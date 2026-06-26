--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  The generic package provides classic sorting routines.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with SPARK.Containers.Functional.Multisets;
with Permutation_Utils;
with Sorting_Proof_Utils;

generic
   type Element is private;
   type Index is (<>);
   type List is array (Index range <>) of Element;
   with function "<"  (Left, Right : Element) return Boolean is <>;
   with function "<=" (Left, Right : Element) return Boolean is <>;
   with function ">"  (Left, Right : Element) return Boolean is <>;
package Sort_Routines with
  SPARK_Mode,
  Always_Terminates
is

   procedure Straight_Selection (This : in out List) with
     Post => Sorted_Ascending (This) and then
             Permutation (This'Old, This);

   procedure Straight_Insertion (This : in out List) with
     Post => Sorted_Ascending (This) and then
             Permutation (This'Old, This);

   procedure Quicksort (This : in out List) with
     Post => Sorted_Ascending (This) and then
             Permutation (This'Old, This);

   function Sorted_Ascending (This : List) return Boolean;

   function Permutation (Left, Right : List) return Boolean with Ghost;
   --  The components of Left and Right are at most reordered, the component
   --  values themselves are not altered

private

   package Element_Multisets is new SPARK.Containers.Functional.Multisets
     (Element, "=");

   package Element_Permutations is new Permutation_Utils
     (Element, Index, List, Element_Multisets);

   package Element_Sorting_Utils is new Sorting_Proof_Utils
     (Element, Index, List, Element_Multisets, Element_Permutations);

   function Permutation (Left, Right : List) return Boolean
     renames Element_Permutations.Permutation;

   function Sorted_Ascending (This : List) return Boolean
     renames Element_Sorting_Utils.Sorted_Ascending;

end Sort_Routines;
