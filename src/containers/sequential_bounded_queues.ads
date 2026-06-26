--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides a bounded queue abstraction.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic

   type Element is private;
   --  The type of values contained by objects of type Queue.

   type Base_Integer is range <>;
   --  The underlying integer type used for counting contained elements and
   --  specifying physical capacities for Queue objects.

package Sequential_Bounded_Queues with
  SPARK_Mode,
  Always_Terminates
is

   pragma Unevaluated_Use_Of_Old (Allow);

   subtype Element_Count is Base_Integer range 0 .. Base_Integer'Last - 1;

   subtype Positive_Element_Count is Element_Count range 1 .. Element_Count'Last;

   type Queue (Capacity : Positive_Element_Count) is limited private with
     Default_Initial_Condition => Empty (Queue),
     Iterable => (First       => First_Iter_Index,
                  Next        => Next_Iter_Index,
                  Has_Element => Iter_Has_Element,
                  Element     => Iter_Value);

   procedure Insert (This : in out Queue; Item : Element) with
     Post => not Empty (This) and then
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
                    Model (This) (K) = Model (This)'Old (K + 1))),
     Global => null;
   --  Inserts Item, overwriting the oldest contained element if This was
   --  already Full when the routine was called.

   procedure Insert_Preserving (This : in out Queue; Item : Element) with
     Pre    => not Full (This),
     Post   => not Empty (This)                      and then
               Extent (This) = Extent (This)'Old + 1 and then
               Front (This) = Front (This)'Old       and then
               Latest_Insertion (This) = Item        and then               
               Model (This) = Model (This)'Old & Item,
     Global => null;
   --  Inserts Item only if This buffer is not already full, therefore never
   --  overwrites data.

   procedure Remove (This : in out Queue; Item : out Element) with
     Pre    => not Empty (This),
     Post   => not Full (This)                       and then
               Extent (This) = Extent (This)'Old - 1 and then
               Item = Next_Element_Out (This)'Old    and then
               (if not Empty (This) then Next_Element_Out (This) = Model (This) (1))  and then
               Model (This)'Old (1) = Item           and then
               --  The rest of This is unchanged. The model is always ordered
               --  oldest to newest, and Get removes the oldest first.
               Model (This) = Model (This)'Old (2 .. Model (This)'Old'Last),
     Global => null;
   --  Gets the next Item from This, oldest first.

   function "=" (Left, Right : Queue) return Boolean with
     Post => ("="'Result = (Extent (Left) = Extent (Right) and then
                            Model (Left) = Model (Right)));
   --  A replacement for predefined equality, this routine only compares the
   --  parts of Left and Right that are logically contained.

   procedure Copy (Source : Queue; Target : in out Queue) with
     Pre    => Target.Capacity >= Extent (Source),
     Post   => Target = Source                     and then
               Empty (Target) = Empty (Source)     and then
               Extent (Target) = Extent (Source)   and then
               Front (Target) = 1                  and then
               Model (Target) = Model (Source)     and then
               (if not Empty (Source) then
                  Next_Element_Out (Target) = Next_Element_Out (Source) and then
                  Latest_Insertion (Target) = Latest_Insertion (Source)),
     Global => null;
   --  A replacement for assignment, this routine only copies to Target that
   --  part of Source which is logically contained at the time of the call.

   function Empty (This : Queue) return Boolean with
     Global => null;

   function Full (This : Queue) return Boolean with
     Global => null;

   function Extent (This : Queue) return Element_Count with
     Global => null;
   --  Returns the number of elements currently contained in This

   procedure Reset (This : out Queue) with
     Post   => Empty (This)               and then
               Front (This) = 1           and then
               Extent (This) = 0          and then
               Model (This) = Empty_Model and then
               Model (This)'Length = 0,
     Global => null;

   procedure Delete (This : in out Queue;  Number_To_Delete : Positive_Element_Count) with
     Post   => not Full (This) and then
               Extent (This) = Extent (This)'Old - Base_Integer'Min (Number_To_Delete, Extent (This)'Old) and then
               (if Number_To_Delete = Extent (This)'Old then Empty (This)) and then
               --  the remaining content is unchanged
               (for all K in 1 .. Extent (This) =>
                  Model (This) (K) = Model (This)'Old (K + Base_Integer'Min (Number_To_Delete, Extent (This)'Old)))
               and then --  the next oldest element out is...
               (if not Empty (This) then Next_Element_Out (This) = Model (This) (1)),
     Global => null;
   --  Deletes the requested number of elements from This, starting with the
   --  oldest. At most the current number of contained elements are deleted.

   function Next_Element_Out (This : Queue) return Element with
     Pre    => not Empty (This),
     Global => null;
   --  Returns the value that would be removed by a subsequent call to Get, or
   --  deleted via Delete, or overwritten via Put when This is full. The value
   --  is the oldest currently contained. This function allows clients to query
   --  the value without having to remove it.

   --  Proof (ghost) functions and data  ------------------------------------------------

   type Queue_Model is array (Positive_Element_Count range <>) of Element with
     Ghost,
     Relaxed_Initialization;

   function Model (This : Queue) return Queue_Model with
      Post => Model'Result'First = 1              and then
              Model'Result'Length = Extent (This) and then
              (for all K in Model'Result'Range => Model'Result (K)'Initialized) and then
              (if Model'Result'Length > 0 then
                  Model'Result (1) = Next_Element_Out (This) and then
                  Model'Result (Model'Result'Last) = Latest_Insertion (This)),
      Ghost;
   --  Returns the current logical contents of This, ordered oldest to newest.

   function Latest_Insertion (This : Queue) return Element with
     Pre => not Empty (This),
     Ghost;

   function Front (This : Queue) return Positive_Element_Count with Ghost;

   Empty_Model : constant Queue_Model (1 .. 0) := [] with Ghost;

  --  Iterator functions  ---------------------------------------------------------------

  --  These functions are defined purely for iteration support and are not
  --  intended to be used by application code.

   function First_Iter_Index (Unused : Queue) return Positive_Element_Count;

   function Next_Iter_Index (Unused : Queue; Position : Positive_Element_Count) return Positive_Element_Count;

   function Iter_Has_Element (This : Queue;  Position : Positive_Element_Count) return Boolean;

   function Iter_Value (This : Queue; Position : Positive_Element_Count) return Element with
     Pre => Iter_Has_Element (This, Position);

private

   type Element_Data is array (Positive_Element_Count range <>) of Element with
     Relaxed_Initialization;

   First_Index : constant Positive_Element_Count := 1;

   type Queue (Capacity : Positive_Element_Count) is record
      Content : Element_Data (First_Index .. Capacity);
      First   : Positive_Element_Count := First_Index;
      Length  : Element_Count := 0;
   end record with
     Type_Invariant =>
        First  in Content'Range and then
        Length in 0 .. Capacity and then
        (if First - 1 <= Capacity - Length then  -- logical content, if any, fits without wrapping around
           (for all K in First .. First + Length - 1 => Content (K)'Initialized)  -- null range if Length = 0
         else  -- logical content wraps around capacity within the array
           (for all K in First .. Capacity                              => Content (K)'Initialized) and then
           (for all K in Content'First .. Length - Capacity + First - 1 => Content (K)'Initialized));
   pragma Annotate (GNATProve,
                    False_Positive,
                    "type ""Queue"" is not fully initialized",
                    "bug in gnatprove from combination of Default_Initial_Condition and relaxed init");

   -----------
   -- Empty --
   -----------

   function Empty (This : Queue) return Boolean is
     (This.Length = 0);

   ----------
   -- Full --
   ----------

   function Full (This : Queue) return Boolean is
     (This.Length = This.Capacity);

   ------------
   -- Extent --
   ------------

   function Extent (This : Queue) return Element_Count is
     (This.Length);

   ----------------------
   -- Next_Element_Out --
   ----------------------

   function Next_Element_Out (This : Queue) return Element is
     (This.Content (This.First));

   -----------
   -- Front --
   -----------

   function Front (This : Queue) return Positive_Element_Count is
     (This.First);

   ----------------
   -- Next_Index --
   ----------------

   function Next_Index
     (This   : Queue;
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

   function "=" (Left, Right : Queue) return Boolean is
     (Left.Length = Right.Length and then
     (for all Offset in 0 .. Left.Length - 1 =>
         Left.Content (Next_Index (Left, Offset)) = Right.Content (Next_Index (Right, Offset))));

   ----------------------
   -- Latest_Insertion --
   ----------------------

   function Latest_Insertion (This : Queue) return Element is
     (This.Content (Next_Index (This, Offset => This.Length - 1)));

end Sequential_Bounded_Queues;
