--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides an abstract data type (ADT) representing a
--  bounded, circular ring buffer. The physical capacity of each object of the
--  type is configured individually, via the object's discriminant. Objects of
--  the type are not thread-safe, hence the term "sequential" in the generic
--  unit's name.
--
--  There are two insertion routines. Procedure Insert will overwrite
--  the oldest contained datum when the buffer object is full. Procedure
--  Insert_Preserving has a precondition to check for the buffer being full, so
--  it does not overwrite any data. The most common use-case for ring buffers
--  is overwriting on full so we use the shorter name for that routine.
--
--  Read-only iteration is supported over any given buffer object, using the
--  generalized iterator syntax.
--
--  The implementation is backed by an array, as usual. Of the various
--  implementations possible, some do not utilize one of the array components
--  in order to distinguish between the Empty and Full states. Other use a
--  count of the number of elements currently contained for that purpose.
--  This implementation uses a counter, and, as a result, for any given buffer
--  object, all array components are available for use. In other words, all
--  array components can be used, and will be used when the buffer object
--  is logically full. That is an important consideration when the array
--  components contain many bytes each, as will happen if the generic package
--  is instantiated with a large generic actual type. The counter is an
--  integral part of the implementation, in fact, because when combined with
--  an index representing the front of the buffer, the rear of the buffer can
--  always be computed (e.g., for inserting a new element).

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic

   type Element is private;
   --  The type of values contained by objects of type Ring_Buffer.

   type Base_Integer is range <>;
   --  The underlying integer type used for counting contained elements, etc.,
   --  as well as specifying physical capacities for buffer objects.

package Sequential_Bounded_Buffers with
  SPARK_Mode,
  Always_Terminates
is

   pragma Unevaluated_Use_Of_Old (Allow);

   subtype Element_Count is Base_Integer range 0 .. Base_Integer'Last - 1;

   subtype Positive_Element_Count is Element_Count range 1 .. Element_Count'Last;

   type Ring_Buffer (Capacity : Positive_Element_Count) is limited private with
     Default_Initial_Condition => Empty (Ring_Buffer),
     Iterable => (First       => First_Iter_Index,
                  Next        => Next_Iter_Index,
                  Has_Element => Iter_Has_Element,
                  Element     => Iter_Value);

   procedure Insert (This : in out Ring_Buffer; Item : Element) with
     Post => not Empty (This)               and then
             Latest_Insertion (This) = Item and then
             (if not Full (This)'Old then -- Item was appended
                 Extent (This) = Extent (This)'Old + 1   and then
                 Front (This) = Front (This)'Old         and then
                 Model (This) = Model (This)'Old & Item
              else  -- Item overwrote the oldest entry; old front (the oldest)
                    -- is dropped and Item is appended as the new newest.
                 Extent (This) = Extent (This)'Old                          and then
                 Front (This) = (Front (This)'Old mod This.Capacity) + 1    and then
                 Model (This) (Model (This)'Last) = Item                    and then
                 (for all K in 1 .. Model (This)'Last - 1 =>
                    Model (This) (K) = Model (This)'Old (K + 1))            and then
                 --  New oldest is what was the second-oldest, unless Capacity = 1
                 Oldest_Insertion (This) = (if Extent (This) = 1 then Item else Model (This)'Old (2))),
     Global => null;
   --  Inserts Item, overwriting the oldest contained element if This was
   --  already Full when the routine was called.

   procedure Insert_Preserving (This : in out Ring_Buffer; Item : Element) with
     Pre    => not Full (This),
     Post   => not Empty (This)                      and then
               Extent (This) = Extent (This)'Old + 1 and then
               Front (This) = Front (This)'Old       and then
               Latest_Insertion (This) = Item        and then
               Model (This) = Model (This)'Old & Item and then
               --  Oldest is preserved if there was one; otherwise the new Item becomes oldest
               (if Empty (This)'Old then
                   Oldest_Insertion (This) = Item
                else
                   Oldest_Insertion (This) = Model (This)'Old (1)),
     Global => null;
   --  Inserts Item only if This buffer is not already full, therefore never
   --  overwrites data.

   procedure Remove (This : in out Ring_Buffer; Item : out Element) with
     Pre    => not Empty (This),
     Post   => not Full (This)                       and then
               Extent (This) = Extent (This)'Old - 1 and then
               Item = Oldest_Insertion (This)'Old    and then
               Model (This)'Old (1) = Item           and then
               --  The rest of This is unchanged. The model is always ordered
               --  oldest to newest, and Remove removes the oldest first.
               Model (This) = Model (This)'Old (2 .. Model (This)'Old'Last) and then
               --  Front advances by one, wrapping at Capacity
               Front (This) = (Front (This)'Old mod This.Capacity) + 1 and then
               --  Newest entry is unchanged whenever any remain
               (if not Empty (This) then Latest_Insertion (This) = Latest_Insertion (This)'Old),
     Global => null;
   --  Gets the next Item from This, oldest first.

   type Elements is array (Positive_Element_Count range <>) of Element;

   procedure Insert_Preserving (This : in out Ring_Buffer; Items : Elements) with
     Pre    => This.Capacity - Extent (This) >= Items'Length and then
               Extent (This) <= Element_Count'Last - Items'Length,
     Post   => (if Items'Length > 0 then not Empty (This))      and then
               Extent (This) = Extent (This)'Old + Items'Length and then
               Front (This) = Front (This)'Old                  and then
               Model (This) = Model (This)'Old & Buffer_Model (Items) and then
               --  Newest is the last appended item, when any items were appended
               (if Items'Length > 0 then Latest_Insertion (This) = Items (Items'Last)) and then
               --  Oldest is preserved if there was one; otherwise the first appended item, if any
               (if not Empty (This)'Old then
                   Oldest_Insertion (This) = Model (This)'Old (1)
                elsif Items'Length > 0 then
                   Oldest_Insertion (This) = Items (Items'First)),
     Global => null;
   --  Inserts Item only if This buffer has sufficient space available,
   --  therefore never overwrites data.

   procedure Remove
     (This  : in out Ring_Buffer;
      Items : out Elements;
      Last  : out Base_Integer)
   with
     Relaxed_Initialization => Items,
     Post   => Last = (if Extent (This)'Old <= Items'Length
                       then Items'First + Extent (This)'Old - 1
                       else Items'First + Items'Length - 1)                 and then
               (for all K in Items'First .. Last => Items (K)'Initialized)  and then
               --  If there was something to remove into, we did so.
               --  It is sufficient to check only Items'Length here, given
               --  that we removed at least one element if possible. If it
               --  was not possible when Items'Length > 0, This must have
               --  been empty, so in either case This is not full now.
               (if Items'Length > 0 then not Full (This))                        and then
               --  If we removed everything then This is Empty now
               (if Last - Items'First + 1 = Extent (This)'Old then Empty (This)) and then
               --  The extent is reduced by the amount removed
               Extent (This) = Extent (This)'Old - (Last - Items'First + 1)      and then
               --  The model length is reduced by the amount actually removed
               --  (which might be zero)
               Model (This)'Length = Model (This)'Old'Length - (Last - Items'First + 1) and then
               --  The remaining content is unchanged
               (for all K in 1 .. Extent (This) =>
                  Model (This) (K) = Model (This)'Old (K + (Last - Items'First + 1)))                      and then
               Buffer_Model (Items) (Items'First .. Last) = Model (This)'Old (1 .. Last - Items'First + 1) and then
               --  The first entry in the model (if any) is always the oldest inserted element
               (if not Empty (This) then Model (This) (1) = Oldest_Insertion (This)) and then
               --  Newest entry is unchanged whenever any remain
               (if not Empty (This) then Latest_Insertion (This) = Model (This)'Old (Model (This)'Old'Last)),
     Global => null;
    --  Removes a slice from This and inserts it into Items, of a length
    --  determined by Items'Length, but no more than the number of
    --  elements in This (which could be zero). The slice to be removed
    --  starts at the front of the buffer. The parameter Last is set to
    --  the last index of Items whose component (of Items) was assigned
    --  a value, unless This was empty on entry, in which case Last is
    --  Items'First - 1 so a slice of Items from Items'Frst .. Last
    --  will be a null slice.

   function "=" (Left, Right : Ring_Buffer) return Boolean with
     Post => ("="'Result = (Extent (Left) = Extent (Right) and then
                            Model (Left) = Model (Right)));
   --  A replacement for predefined equality, this routine only compares the
   --  parts of Left and Right that are logically contained.

   procedure Copy (Source : Ring_Buffer; Target : in out Ring_Buffer) with
     Pre    => Target.Capacity >= Extent (Source),
     Post   => Target = Source                     and then
               Empty (Target) = Empty (Source)     and then
               Extent (Target) = Extent (Source)   and then
               Front (Target) = 1                  and then
               Model (Target) = Model (Source)     and then
               (if not Empty (Source) then
                  Oldest_Insertion (Target) = Oldest_Insertion (Source) and then
                  Latest_Insertion (Target) = Latest_Insertion (Source)),
     Global => null;
   --  A replacement for assignment, this routine only copies to Target that
   --  part of Source which is logically contained at the time of the call.

   function Empty (This : Ring_Buffer) return Boolean with
     Global => null;

   function Full (This : Ring_Buffer) return Boolean with
     Global => null;

   function Extent (This : Ring_Buffer) return Element_Count with
     Global => null;

   procedure Reset (This : out Ring_Buffer) with
     Post   => Empty (This)               and then
               Front (This) = 1           and then
               Extent (This) = 0          and then
               Model (This) = Empty_Model and then
               Model (This)'Length = 0,
     Global => null;

   procedure Delete
     (This             : in out Ring_Buffer;
      Number_To_Delete : Positive_Element_Count;
      Number_Deleted   : out Element_Count)
   with
     Post   => not Full (This) and then
               Number_Deleted = Element_Count'Min (Number_To_Delete, Extent (This)'Old) and then
               Extent (This) = Extent (This)'Old - Number_Deleted and then
               --  Empty exactly when we asked to delete at least every contained element
               Empty (This) = (Number_To_Delete >= Extent (This)'Old) and then
               --  the remaining content is unchanged
               (for all K in 1 .. Extent (This) =>
                  Model (This) (K) = Model (This)'Old (K + Number_Deleted)) and then
               (if not Empty (This) then Oldest_Insertion (This) = Model (This) (1)) and then
               --  Newest entry is unchanged whenever any remain
               (if not Empty (This) then Latest_Insertion (This) = Model (This)'Old (Model (This)'Old'Last)) and then
               --  Front advances by the actual deletion count, wrapping at Capacity
               (if Front (This)'Old <= This.Capacity - Number_Deleted then
                  Front (This) = Front (This)'Old + Number_Deleted
                else
                  Front (This) = Front (This)'Old - This.Capacity + Number_Deleted),
     Global => null;
   --  Deletes the requested number of elements from This, starting with the
   --  oldest. At most the current number of contained elements are deleted.

   function Oldest_Insertion (This : Ring_Buffer) return Element with
     Pre    => not Empty (This),
     Global => null;
   --  Returns the value that would be removed by a subsequent call to Remove, or
   --  deleted via Delete, or overwritten via Insert when This is full. The value
   --  is the oldest currently contained. This function allows clients to query
   --  the value without having to remove it.

   --  Proof (ghost) functions and data  ------------------------------------------------

   type Buffer_Model is array (Positive_Element_Count range <>) of Element with
     Ghost,
     Relaxed_Initialization;

   function Model (This : Ring_Buffer) return Buffer_Model with
      Post => Model'Result'First = 1              and then
              Model'Result'Length = Extent (This) and then
              (for all K in Model'Result'Range => Model'Result (K)'Initialized) and then
              (if Model'Result'Length > 0 then
                  Model'Result (1) = Oldest_Insertion (This) and then
                  Model'Result (Model'Result'Last) = Latest_Insertion (This)),
      Ghost;
   --  Returns the current logical contents of This, ordered oldest to newest.

   function Latest_Insertion (This : Ring_Buffer) return Element with
     Pre => not Empty (This),
     Ghost;

   function Front (This : Ring_Buffer) return Positive_Element_Count with Ghost;

   Empty_Model : constant Buffer_Model (1 .. 0) := [] with Ghost;

  --  Iterator functions  ---------------------------------------------------------------

  --  These functions are defined purely for iteration support and are not
  --  intended to be used by application code.

   function First_Iter_Index (Unused : Ring_Buffer) return Positive_Element_Count;

   function Next_Iter_Index
     (Unused   : Ring_Buffer;
      Position : Positive_Element_Count)
   return Positive_Element_Count;

   function Iter_Has_Element
     (This     : Ring_Buffer;
      Position : Positive_Element_Count)
   return Boolean;

   function Iter_Value
     (This     : Ring_Buffer;
      Position : Positive_Element_Count)
   return Element with
     Pre  => Iter_Has_Element (This, Position),
     Post => Iter_Value'Result = Model (This) (Position);

private

   First_Index : constant Positive_Element_Count := 1;

   type Element_List is array (Positive_Element_Count range <>) of Element with
     Relaxed_Initialization;

   type Ring_Buffer (Capacity : Positive_Element_Count) is record
      Content : Element_List (First_Index .. Capacity);
      First   : Positive_Element_Count := First_Index;
      Length  : Element_Count := 0;
   end record with
     Type_Invariant =>
        First  in Content'Range and then
        Length in 0 .. Capacity and then
        (if First - 1 <= Capacity - Length then
            --  Current content, if any, does not wrap around Capacity within
            --  the array. Note the following is a null range if Length = 0.
            (for all K in First .. First + Length - 1 => Content (K)'Initialized)
         else
            -- Current content wraps around Capacity within the array.
            (for all K in First .. Capacity => Content (K)'Initialized) and then
            (for all K in Content'First .. Length - Capacity + First - 1 =>
                Content (K)'Initialized));
   pragma Annotate (GNATProve,
                    False_Positive,
                    "type ""Ring_Buffer"" is not fully initialized",
                    "gnatprove bug from combination of Default_Initial_Condition and relaxed init");

   -----------
   -- Empty --
   -----------

   function Empty (This : Ring_Buffer) return Boolean is
     (This.Length = 0);

   ----------
   -- Full --
   ----------

   function Full (This : Ring_Buffer) return Boolean is
     (This.Length = This.Capacity);

   ------------
   -- Extent --
   ------------

   function Extent (This : Ring_Buffer) return Element_Count is
     (This.Length);

   ----------------------
   -- Next_Element_Out --
   ----------------------

   function Oldest_Insertion (This : Ring_Buffer) return Element is
     (This.Content (This.First));

   -----------
   -- Front --
   -----------

   function Front (This : Ring_Buffer) return Positive_Element_Count is
     (This.First);

   ----------------
   -- Next_Index --
   ----------------

   function Next_Index
     (This   : Ring_Buffer;
      Offset : Element_Count)
     return Positive_Element_Count
   is
     (if This.First <= This.Capacity - Offset then
         This.First + Offset
      else -- wrapping around
         Offset - This.Capacity + This.First)
     --  this is equal to (((This.First + Offset - 1) mod This.Capacity) + 1)
     --  but without overflow issues
   with
     Pre  => Offset in 0 .. This.Capacity and then
             This.First in 1 .. This.Capacity,
     Post => Next_Index'Result in This.Content'Range;

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Ring_Buffer) return Boolean is
     (Left.Length = Right.Length and then
     (for all Offset in 0 .. Left.Length - 1 =>
         Left.Content (Next_Index (Left, Offset)) = Right.Content (Next_Index (Right, Offset))));

   ----------------------
   -- Latest_Insertion --
   ----------------------

   function Latest_Insertion (This : Ring_Buffer) return Element is
     (This.Content (Next_Index (This, Offset => This.Length - 1)));

end Sequential_Bounded_Buffers;
