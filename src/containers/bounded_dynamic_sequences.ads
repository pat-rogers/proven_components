--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides an ADT for physically bounded but logically
--  variable-length sequences as a wrapper to the array type passed to the
--  generic formal parameter List.
--
--  For example, to get "dynamic" strings:
--
--     package Variable_Length_Strings is new Bounded_Dynamic_Sequences
--       (Component     => Character,
--        List_Index    => Positive,
--        List          => String,
--        "="           => "=");
--
--     type Dynamic_String is new Variable_Length_Strings.Sequence;
--
--  Or, for financial transactions:
--
--     with Bounded_Dynamic_Sequences;
--     with Financial;
--
--     package Bounded_Dynamic_Transactions is new Bounded_Dynamic_Sequences
--       (Component     => Financial.Currency,
--        List_Index    => Financial.Positive_Transaction_Count,
--        List          => Financial.Transactions_List,
--        "="           => Financial."=");

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic
   type Component is private;
   type List_Index is range <>;
   type List is array (List_Index range <>) of Component;
   with function "=" (Left, Right : List) return Boolean is <>;
package Bounded_Dynamic_Sequences with
  SPARK_Mode,
  Always_Terminates
is
   pragma Pure;

   pragma Unevaluated_Use_Of_Old (Allow);

   Maximum_Length : constant List_Index := List_Index'Last;
   --  The physical maximum for the upper bound of the wrapped List array
   --  values.  Defined for readability in predicates.

   subtype Natural_Index is List_Index'Base range 0 .. Maximum_Length;

   subtype Index is List_Index range 1 .. Maximum_Length;

   type Sequence (Capacity : Natural_Index) is private with
     Default_Initial_Condition => Empty (Sequence),
     Iterable => (First       => First_Index,
                  Next        => Next_Index,
                  Has_Element => Has_Element,
                  Element     => Value);
   --  A wrapper for List array values in which Capacity represents the
   --  physical upper bound. Capacity is, therefore, the maximum number of
   --  Component values possibly contained by the associated Sequence instance.
   --  However, not all of the physical capacity of a Sequence need be used at
   --  any moment, leading to the notion of a logical current length ranging
   --  from zero to Capacity.

   Null_List : constant List := [];

   function Instance
     (Content : List)
   return Sequence
   with
     Pre  => Content'Length <= Maximum_Length,
     Post => Length (Instance'Result) = Content'Length and then
             Value (Instance'Result) = Content and then
             Instance'Result = Content and then
             Instance'Result.Capacity = Content'Length and then
             Contains_At (Instance'Result, 1, Content),
     Global => null;

   function Instance
     (Capacity : Natural_Index;
      Content  : Component)
   return Sequence
   with
     Pre  => Capacity >= 1,
     Post => Length (Instance'Result) = 1 and then
             Value (Instance'Result) (1) = Content and then
             Instance'Result.Capacity = Capacity and then
             Instance'Result = Content and then
             Contains_At (Instance'Result, 1, Content),
     Global => null;

   function Instance
     (Capacity : Natural_Index;
      Content  : List)
   return Sequence
   with
     Pre  => Content'Length <= Capacity and then
             Content'Length <= Maximum_Length,
     Post => Instance'Result.Capacity = Capacity and then
             Length (Instance'Result) = Content'Length and then
             Value (Instance'Result) = Content and then
             Instance'Result = Content and then
             Contains_At (Instance'Result, 1, Content),
     Global => null;

   function Value (This : Sequence) return List with
     Post => Value'Result'Length = Length (This) and then
             Value'Result'First = 1 and then
             Value'Result'Last = Length (This),
     Inline;
   --  Returns any content of this sequence. The value returned is the
   --  "logical" value in that only that slice which is currently assigned
   --  is returned, as opposed to the entire physical representation.

   function Value (This : Sequence; Position : Index) return Component with
     Pre  => Has_Element (This, Position),
     Post => Contains_At (This, Position, Value'Result),
     Inline;

   function Length (This : Sequence) return Natural_Index with
     Inline;
   --  Returns the logical length of This, i.e., the length of the slice of
   --  This that is currently assigned a value.

   function Empty (This : Sequence) return Boolean with
     Post => Empty'Result = (Length (This) = 0),
     Inline;

   procedure Clear (This : out Sequence) with
     Post => Empty (This) and then
             Length (This) = 0 and then
             Value (This) = Null_List,
     Global => null,
     Inline;

   procedure Copy (Source : Sequence; To : in out Sequence) with
     Pre  => To.Capacity >= Length (Source),
     Post => Value (To) = Value (Source) and then
             Length (To) = Length (Source) and then
             To = Source and then
             Contains_At (To, 1, Source),
     Global => null;
   --  Copies the logical value of Source, the RHS, to the LHS sequence To. The
   --  prior value of To is lost.

   procedure Copy (Source : List; To : in out Sequence) with
     Pre  => To.Capacity >= Source'Length,
     Post => Value (To) = Source and then
             Length (To) = Source'Length and then
             To = Source and then
             Contains_At (To, 1, Source),
     Global => null;
   --  Copies the value of the array Source, the RHS, to the LHS sequence To.
   --  The prior value of To is lost.

   procedure Copy (Source : Component; To : in out Sequence) with
     Pre  => To.Capacity > 0,
     Post => Value (To) (1) = Source and then
             Length (To) = 1 and then
             To = Source and then
             Contains_At (To, 1, Source),
     Global => null;
   --  Copies the value of the individual array component Source, the RHS, to
   --  the LHS sequence To. The prior value of To is lost.

   function "=" (Left, Right : Sequence) return Boolean with
     Inline;

   function "=" (Left : Sequence;  Right : List) return Boolean with
     Inline;

   function "=" (Left : List;  Right : Sequence) return Boolean with
     Inline;

   function "=" (Left : Sequence;  Right : Component) return Boolean with
     Inline;

   function "=" (Left : Component;  Right : Sequence) return Boolean with
     Inline;

   function Normalized (L : List) return List with
     Pre  => L'Length <= Maximum_Length,
     Post => Normalized'Result'First = 1 and then
             Normalized'Result'Last = L'Length and then
             Normalized'Result = L;
   --  Slides the input into a 1-based array

   function "&" (Left : Sequence; Right : Sequence) return Sequence with
     Pre  => Length (Left) <= Maximum_Length - Length (Right),
     Post => Value ("&"'Result) = Value (Left) & Value (Right) and then
             Value ("&"'Result)'First = 1 and then
             Length ("&"'Result) = Length (Left) + Length (Right) and then
             "&"'Result.Capacity = Length (Left) + Length (Right);

   function "&" (Left : Sequence; Right : List) return Sequence with
     Pre  => Length (Left) <= Maximum_Length - Right'Length,
     Post => Value ("&"'Result) = Value (Left) & Right and then
             Value ("&"'Result)'First = 1 and then
             Length ("&"'Result) = Length (Left) + Right'Length and then
             "&"'Result.Capacity = Length (Left) + Right'Length;

   function "&" (Left : List; Right : Sequence) return Sequence with
     Pre  => Left'Length <= Maximum_Length - Length (Right),
     Post => Value ("&"'Result) = Normalized (Left) & Value (Right) and then
             Value ("&"'Result)'First = 1 and then
             Length ("&"'Result) = Left'Length + Length (Right) and then
             "&"'Result.Capacity = Left'Length + Length (Right);

   function "&" (Left : Sequence; Right : Component) return Sequence with
     Pre  => Length (Left) <= Maximum_Length - 1,
     Post => Value ("&"'Result) = Value (Left) & Right and then
             Value ("&"'Result)'First = 1 and then
             Length ("&"'Result) = Length (Left) + 1 and then
             "&"'Result.Capacity = Length (Left) + 1;

   function "&" (Left : Component; Right : Sequence) return Sequence with
     Pre  => Length (Right) <= Maximum_Length - 1,
     Post => Value ("&"'Result) = Left & Value (Right) and then
             Value ("&"'Result)'First = 1 and then
             Length ("&"'Result) = 1 + Length (Right) and then
             "&"'Result.Capacity = 1 + Length (Right);

   procedure Append (Tail : Sequence; To : in out Sequence) with
     Pre  => Length (Tail) <= To.Capacity - Length (To) and then
             Length (To) < Maximum_Length,
     Post => To = Value (To'Old) & Value (Tail) and then
             To = To'Old & Value (Tail) and then
             Value (To) = Value (To'Old) & Value (Tail) and then
             Length (To) = Length (To'Old) + Length (Tail) and then
             Contains_At (To, Length (To'Old) + 1, Tail) and then
             (if Length (Tail) > 0 then Length (To) > 0) and then
             --  the Tail is at the end
             Value (To) (Length (To'Old) + 1 .. Length (To)) = Value (Tail) and then
             --  the rest are not changed
             (for all K in Value (To)'First .. Value (To)'Last - Length (Tail) =>
                Value (To, K) = Value (To'Old, K)),
     Global => null;

   procedure Append (Tail : List; To : in out Sequence) with
     Pre  => Tail'Length <= To.Capacity - Length (To) and then
             Length (To) < Maximum_Length,
     Post => To = Value (To'Old) & Tail                    and then
             To = To'Old & Tail                            and then
             Value (To) = Value (To'Old) & Tail            and then
             Length (To) = Length (To'Old) + Tail'Length   and then
             Contains_At (To, Length (To'Old) + 1, Tail)   and then
             (if Tail'Length > 0 then Length (To) > 0)     and then
             --  the Tail is at the end
             Value (To) (Length (To'Old) + 1 .. Length (To)) = Tail and then
             --  the rest are not changed
             (for all K in Value (To)'First .. Value (To)'Last - Tail'Length =>
                Value (To, K) = Value (To'Old, K)),
     Global => null;

   procedure Append (Tail : Component; To : in out Sequence) with
     Pre  => Length (To) <= To.Capacity - 1,
     Post => Length (To) = Length (To'Old) + 1 and then
             Contains_At (To, Length (To'Old) + 1, Tail) and then
             --  the Tail is at the end
             Value (To) = Value (To'Old) & Tail and then
             --  the rest are not changed
             (for all K in Value (To)'First .. Value (To)'Last - 1 =>
                Value (To, K) = Value (To'Old, K)),
     Global => null;

   procedure Amend
     (This  : in out Sequence;
      By    : Sequence;
      Start : Index)
   with
     Pre  => Length (By) > 0 and then
             Start <= Length (This) and then
             Start - 1 in 1 .. This.Capacity - Length (By) and then
             Start <= Maximum_Length - Length (By),
     Post => Value (This) (Start .. Start + Length (By) - 1) = Value (By) and then
             (if Start + Length (By) - 1 > Length (This'Old)
                then Length (This) = Start + Length (By) - 1
                else Length (This) = Length (This'Old)) and then
             Contains_At (This, Start, By) and then
             --  any content before the overwritten part is unchanged:
             (for all K in 1 .. Start - 1 =>
                Value (This) (K) = Value (This'Old) (K)) and then
             --  any content after the overwritten part is unchanged:
             (for all K in (Start + Length (By)) .. Value (This)'Length =>
                Value (This) (K) = Value (This'Old) (K)),
     Global => null;
   --  Overwrites any content of This, beginning at Start, with the logical
   --  value of the Sequence argument By

   procedure Amend
     (This  : in out Sequence;
      By    : List;
      Start : Index)
   with
     Pre  => By'Length > 0 and then
             Start <= Length (This) and then
             Start - 1 in 1 .. This.Capacity - By'Length and then
             Start <= Maximum_Length - By'Length,
     Post => Value (This) (Start .. Start + By'Length - 1) = By and then
             (if Start + By'Length - 1 > Length (This'Old)
                then Length (This) = Start + By'Length - 1
                else Length (This) = Length (This'Old)) and then
             Contains_At (This, Start, By) and then
             --  any content before the overwritten part is unchanged:
             (for all K in 1 .. Start - 1 =>
                 Value (This) (K) = Value (This'Old) (K)) and then
             --  any content after the overwritten part is unchanged:
             (for all K in (Start + By'Length) .. Value (This)'Length =>
                 Value (This) (K) = Value (This'Old) (K)),
     Global => null;
   --  Overwrites any content of This, beginning at Start, with the value of
   --  List argument By

   procedure Amend
     (This  : in out Sequence;
      By    : Component;
      Start : Index)
   with
     Pre  => Start <= Length (This) and then
             Start <= Maximum_Length - 1,
     Post => Value (This) (Start) = By and then
             Length (This) = Length (This)'Old and then
             Contains_At (This, Start, By) and then
             --  the rest is unchanged:
             Value (This) = Value (This)'Old'Update (Start => By),
     Global => null;
   --  Overwrites any content of This, at position Start, with the value of
   --  the single Component argument By

   function Location (Fragment : Sequence; Within : Sequence) return Natural_Index with
     Pre  => Length (Fragment) > 0,
     Post => Location'Result in 0 .. Within.Capacity and then
             (if Length (Fragment) > Within.Capacity then Location'Result = 0) and then
             (if Length (Fragment) > Length (Within) then Location'Result = 0) and then
             (if Location'Result > 0 then Contains_At (Within, Location'Result, Fragment));
   --  Returns the starting index of the logical value of the sequence Fragment
   --  in the sequence Within, if any. Returns 0 when the fragment is not
   --  found.
   --  NB: The implementation is not the best algorithm...

   function Location (Fragment : List; Within : Sequence) return Natural_Index with
     Pre  => Fragment'Length > 0,
     Post => Location'Result in 0 .. Length (Within) and then
             (if Fragment'Length > Within.Capacity then Location'Result = 0) and then
             (if Fragment'Length > Length (Within) then Location'Result = 0) and then
             (if Location'Result > 0 then Contains_At (Within, Location'Result, Fragment));
   --  Returns the starting index of the value of the array Fragment in the
   --  sequence Within, if any. Returns 0 when the fragment is not found.
   --  NB: The implementation is a simple linear search...

   function Location (Fragment : Component; Within : Sequence) return Natural_Index with
     Post => Location'Result in 0 .. Length (Within) and then
             (if Location'Result > 0 then
                Value (Within, Location'Result) = Fragment and then
                Contains_At (Within, Location'Result, Fragment));
   --  Returns the index of the value of the component Fragment within the
   --  sequence Within, if any. Returns 0 when the fragment is not found.

   function Contains_At
     (Within   : Sequence;
      Start    : Index;
      Fragment : Sequence)
   return Boolean with Inline;

   function Contains_At
     (Within   : Sequence;
      Start    : Index;
      Fragment : List)
   return Boolean with Inline;

   function Contains_At
     (Within   : Sequence;
      Position : Index;
      Fragment : Component)
   return Boolean with Inline;

  --  Iterators  --------------------------------------------------------------

  --  These functions are defined purely for iteration support and are not
  --  intended to be used by application code.

   function First_Index (Dummy : Sequence) return Natural_Index;

   function Has_Element
     (Container : Sequence;
      Position  : Natural_Index)
   return Boolean;

   function Next_Index
     (Unused : Sequence;
      Position  : Natural_Index)
   return Natural_Index;

   function Last_Index (Container : Sequence) return Natural_Index;

private

   type Content_List is array (List_Index range <>) of Component with
     Relaxed_Initialization;
   --  A separate array type is required to apply Relaxed_Initialization
   --  since the generic formal List cannot be annotated directly.
   --  Only the slice 1 .. Current_Length need be initialized at any time.

   type Sequence (Capacity : Natural_Index) is record
      Current_Length : Natural_Index := 0;
      Content        : Content_List (1 .. Capacity);
   end record
     with Type_Invariant =>
            Current_Length in 0 .. Capacity and then
            (for all K in 1 .. Current_Length => Content (K)'Initialized);
   pragma Annotate (GNATProve,
                    False_Positive,
                    "type ""Sequence"" is not fully initialized",
                    "Relaxed_Initialization on Content; only 1 .. Current_Length need be initialized");

   ------------
   -- Length --
   ------------

   function Length (This : Sequence) return Natural_Index is
     (This.Current_Length);

   -----------
   -- Value --
   -----------

   function Value (This : Sequence) return List is
     (List (This.Content (1 .. This.Current_Length)));

   -----------
   -- Value --
   -----------

   function Value (This : Sequence; Position : Index) return Component is
     (This.Content (Position));

   -----------
   -- Empty --
   -----------

   function Empty (This : Sequence) return Boolean is
     (This.Current_Length = 0);

   -----------------
   -- Contains_At --
   -----------------

   function Contains_At
     (Within   : Sequence;
      Start    : Index;
      Fragment : List)
   return Boolean
   is
     (Start - 1 <= Within.Current_Length - Fragment'Length
      and then
      List (Within.Content (Start .. Start + (Fragment'Length - 1))) = Fragment);
   --  note that this includes the case of a null slice on each side, eg
   --  when Start = 1 and Fragment'Length = 0, which is intended to return
   --  True

   -----------------
   -- Contains_At --
   -----------------

   function Contains_At
     (Within   : Sequence;
      Start    : Index;
      Fragment : Sequence)
   return Boolean
   is
     (Contains_At (Within, Start, Value (Fragment)));

   -----------------
   -- Contains_At --
   -----------------

   function Contains_At
     (Within   : Sequence;
      Position : Index;
      Fragment : Component)
   return Boolean
   is
     (Position in 1 .. Within.Current_Length
      and then
      Within.Content (Position) = Fragment);

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Sequence) return Boolean is
     (Value (Left) = Value (Right));

   ---------
   -- "=" --
   ---------

   function "=" (Left : Sequence;  Right : List) return Boolean is
     (Value (Left) = Right);

   ---------
   -- "=" --
   ---------

   function "=" (Left : List;  Right : Sequence) return Boolean is
     (Right = Left);

   ---------
   -- "=" --
   ---------

   function "=" (Left : Sequence;  Right : Component) return Boolean is
      (Left.Current_Length = 1 and then Left.Content (1) = Right);

   ---------
   -- "=" --
   ---------

   function "=" (Left : Component;  Right : Sequence) return Boolean is
     (Right = Left);

   -----------------
   -- First_Index --
   -----------------

   function First_Index (Dummy : Sequence) return Natural_Index is
     (Dummy.Content'First);

   -----------------
   -- Has_Element --
   -----------------

   function Has_Element
     (Container : Sequence;
      Position  : Natural_Index)
   return Boolean
   is
     (Position in 1 .. Container.Current_Length);

   ----------------
   -- Next_Index --
   ----------------

   function Next_Index
     (Unused   : Sequence;
      Position : Natural_Index)
   return Natural_Index
   is
     (if Position in 0 .. Maximum_Length - 1 then Position + 1 else 1);

   ----------------
   -- Last_Index --
   ----------------

   function Last_Index (Container : Sequence) return Natural_Index is
     (Container.Current_Length);

   ---------
   -- "&" --
   ---------

   function "&" (Left : Sequence; Right : Sequence) return Sequence is
     (Instance
        (Capacity => Left.Current_Length + Right.Current_Length,
         Content  => Value (Left) & Value (Right)));

   ---------
   -- "&" --
   ---------

   function "&" (Left : Sequence; Right : List) return Sequence is
     (Instance
        (Capacity => Left.Current_Length + Right'Length,
         Content  => Value (Left) & Right));

   ---------
   -- "&" --
   ---------

   function "&" (Left : List; Right : Sequence) return Sequence is
     (Instance
        (Capacity => Left'Length + Right.Current_Length,
         Content  => Normalized (Left) & Value (Right)));

   ---------
   -- "&" --
   ---------

   function "&" (Left : Sequence; Right : Component) return Sequence is
     (Instance
        (Capacity => Left.Current_Length + 1,
         Content  => Value (Left) & Right));

   ---------
   -- "&" --
   ---------

   function "&" (Left : Component; Right : Sequence) return Sequence is
     (Instance
        (Capacity => Right.Current_Length + 1,
         Content  => Left & Value (Right)));

   --------------
   -- Location --
   --------------

   function Location (Fragment : Sequence; Within : Sequence) return Natural_Index is
     (Location (Value (Fragment), Within));

end Bounded_Dynamic_Sequences;
