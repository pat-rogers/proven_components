--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides lemmas for proving the extents of lists of
--  Booleans, in which the type List is a generic formal constrained array
--  of Boolean components. The index type for the array is a generic formal
--  discrete type named Element.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic

   type Element is (<>);
   --  The type of value contained by List objects.
   --
   --  NB: This type also determines how big a List object will be, because
   --  the type List is represented as an array of Boolean components, with
   --  Element as the index for that array type. Therefore, there will be
   --  Element'Range_Length Boolean components, so keep that in mind when
   --  you decide on the generic actual type.

   type List is array (Element) of Boolean;
   --  The type for which Extent is computed, i.e., the number of components in
   --  a List object that are True.

   type Counter is range <>;
   --  The integer type used for counting the number of components of a List
   --  object, and so on. Must include zero.

package Boolean_Array_Extent with
  SPARK_Mode,
  Always_Terminates
is

   function Extent (This : List) return Counter with
     Post => Extent'Result in 0 .. Counter (Element'Range_Length)               and then
             (if (for all K in Element => not This (K)) then Extent'Result = 0) and then
             (if (for all K in Element => This (K)) then Extent'Result = Counter (Element'Range_Length));
   --  Returns the current number of True components in This.
   --  Note this is not a ghost routine.

   procedure Lemma_Extent_Zero (S : List) with
     Pre => (for all K in Element => not S (K)),
     Post => Extent (S) = 0,
     Ghost;

   procedure Lemma_Extent_Incremented (Before, After : List; E : Element) with
     Pre  => (for all K in Element => (if K /= E then Before (K) = After (K))) and then
             Before (E) = False and then
             After (E) = True,
     Post => Extent (After) = Extent (Before) + 1,
     Ghost;

   procedure Lemma_Extent_Decremented (Before, After : List; E : Element) with
     Pre  => (for all K in Element => (if K /= E then Before (K) = After (K))) and then
             Before (E) = True and then
             After (E) = False,
     Post => Extent (After) = Extent (Before) - 1,
     Ghost;

   procedure Lemma_Extent_Equal (Left, Right : List) with
     Pre  => (for all C in Element => (Left (C) = Right (C))),
     Post => Extent (Left) = Extent (Right),
     Ghost;

private

   function Sum (This : List; From : Element) return Counter with
     Post => Sum'Result in 0 .. Element'Pos (Element'Last) - Element'Pos (From) + 1  and then
             (if (for all K in Element range From .. Element'Last => not This (K))
              then Sum'Result = 0)                                                   and then
             (if (for all K in Element range From .. Element'Last => This (K))
              then Sum'Result = Element'Pos (Element'Last) - Element'Pos (From) + 1),
     Subprogram_Variant => (Increases => From);

   function Sum (This : List; From : Element) return Counter is
     (if From = Element'Last
      then Boolean'Pos (This (From))
      else Boolean'Pos (This (From)) + Sum (This, Element'Succ (From)));

   function Extent (This : List) return Counter is
      (Sum (This, From => Element'First));

end Boolean_Array_Extent;
