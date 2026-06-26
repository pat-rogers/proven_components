--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides functional utilities, and lemmas for proof, of
--  sorting routines.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with SPARK.Containers.Functional.Multisets;
with Permutation_Utils;

generic
   type Element is private;
   type Index is (<>);
   type List is array (Index range <>) of Element;

   with package Element_Multisets is new SPARK.Containers.Functional.Multisets
     (Element, "=");

   with package Element_Permutations is new Permutation_Utils
     (Element, Index, List, Element_Multisets);

   with function "<=" (Left, Right : Element) return Boolean is <>;
package Sorting_Proof_Utils with
  SPARK_Mode,
  Always_Terminates
is

   function Sorted_Ascending (This : List) return Boolean is
     (for all J in This'Range =>
        (for all K in This'First .. Index'Pred (J) =>
           This (K) <= This (J)));

   function Midpoint (Left, Right : Index) return Index is
      (Index'Val (Index'Pos (Left) + (Index'Pos (Right) - Index'Pos (Left)) / 2))
   with Pre => Left <= Right;

   function "+" (Left : Index; Right : Natural) return Index is
      (Index'Val (Index'Pos (Left) + Right))
   with Pre => Index'Pos (Left) <= Index'Pos (Index'Last) - Right;

   function "-" (Left : Index; Right : Natural) return Index is
      (Index'Val (Index'Pos (Left) - Right))
   with Pre => Index'Pos (Left) - Index'Pos (Index'First) >= Right;

   function "+" (Left, Right : Index) return Index is
      (Index'Val (Index'Pos (Left) + Index'Pos (Right)))
   with Pre => Index'Pos (Left) <= Index'Pos (Index'Last) - Index'Pos (Right);

   function "-" (Left, Right : Index) return Index is
      (Index'Val (Index'Pos (Left) - Index'Pos (Right)))
   with Pre => Index'Pos(Left) >= Index'Pos(Index'First) + Index'Pos(Right);

   use Element_Permutations;

   procedure Lemma_Sorted_Concat
     (A : List; Low, Mid, High : Index)
   with
     Ghost,
     Pre  => Low in A'Range                     and then
             High in A'Range                    and then
             Low <= Mid                         and then
             Mid <= High                        and then
             Index'Pos (Low)  in Integer'Range  and then
             Index'Pos (Mid)  in Integer'Range  and then
             Index'Pos (High) in Integer'Range  and then
             Sorted_Ascending (A (Low .. Mid))  and then
             (Mid = High or else
              (Mid < Index'Last and then
               Sorted_Ascending (A (Index'Succ (Mid) .. High))))
             and then
             (for all K in Low .. Mid => A (K) <= A (Mid))
             and then
             (Mid = High or else
              (Mid < Index'Last and then
               (for all K in Index'Succ (Mid) .. High => A (Mid) <= A (K)))),
     Post => Sorted_Ascending (A (Low .. High)),
     Global => null;
   --  Ghost lemma (axiom) proving that two sorted segments with proper
   --  ordering can be concatenated to form a sorted whole.
   --
   --  This lemma is essential for divide-and-conquer sorting algorithms like
   --  quicksort. Given two sorted sub-arrays A (Low..Mid) and A (Succ(Mid)..High)
   --  where all elements in the left segment are <= the pivot at Mid, and all
   --  elements in the right segment are >= the pivot, this lemma establishes
   --  that the entire range A (Low..High) is sorted.

   procedure Lemma_Sorted_Frame
     (Old_A : List;
      New_A : List;
      Low   : Index;
      High  : Index)
   with
     Ghost,
     Global => null,
     Pre  => Low in Old_A'Range   and then
             High in Old_A'Range  and then
             Low in New_A'Range   and then
             High in New_A'Range  and then
             Sorted_Ascending (Old_A (Low .. High)) and then
             (for all K in Low .. High => New_A (K) = Old_A (K)),
     Post => Sorted_Ascending (New_A (Low .. High));
   --  Ghost lemma (axiom) proving that sortedness is preserved when elements
   --  are unchanged.
   --
   --  Given that Old_A (Low..High) is sorted in ascending order and every
   --  element in New_A (Low..High) equals the corresponding element in Old_A,
   --  this lemma establishes that New_A (Low..High) is also sorted. This is
   --  sound because sortedness depends only on element values and their
   --  ordering, not on array identity.

   procedure Lemma_Sorted_Subrange
     (A : List;
      Low, High, New_Low, New_High : Index)
   with
     Ghost,
     Global => null,
     Pre  => Low in A'Range              and then
             High in A'Range             and then
             New_Low in Low .. High      and then
             New_High in New_Low .. High and then
             Sorted_Ascending (A (Low .. High)),
    Post => Sorted_Ascending (A (New_Low .. New_High));
   --  Ghost lemma (axiom) proving that a sub-range of a sorted array is
   --  sorted.
   --
   --  Given that A (Low..High) is sorted in ascending order, this lemma
   --  establishes that any contiguous sub-range A (New_Low..New_High) within
   --  that range is also sorted. This is sound because the ordering
   --  relationship between adjacent elements is preserved in any sub-range.

   procedure Lemma_Sorted_Shift_Right
     (Old_A    : List;
      New_A    : List;
      Old_Low  : Index;
      Old_High : Index)
   with
     Ghost,
     Global => null,
     Pre  => Old_Low in Old_A'Range                         and then
             Old_High in Old_A'Range                        and then
             Old_Low <= Old_High                            and then
             Index'Pos (Old_High) < Index'Pos (Index'Last)  and then
             Index'Succ (Old_Low) in New_A'Range            and then
             Index'Succ (Old_High) in New_A'Range           and then
             Sorted_Ascending (Old_A (Old_Low .. Old_High)) and then
             (for all K in Old_Low .. Old_High =>
                New_A (Index'Succ (K)) = Old_A (K)),
   Post => Sorted_Ascending (New_A (Index'Succ (Old_Low) .. Index'Succ (Old_High)));
   --  Ghost lemma (axiom) proving that shifting a sorted region right by
   --  one position preserves sortedness.
   --
   --  Given that Old_A (Old_Low..Old_High) is sorted and each element has
   --  been copied one position to the right in New_A, this lemma establishes
   --  that New_A (Succ(Old_Low)..Succ(Old_High)) is sorted. This is sound
   --  because the relative ordering of elements is unchanged by a uniform
   --  positional shift.

   procedure Lemma_Sorted_Max
     (A : List; Low, High : Index)
   with
     Ghost,
     Global => null,
     Pre  => Low in A'Range  and then
             High in A'Range and then
             Low <= High     and then
             Sorted_Ascending (A (Low .. High)),
     Post => (for all K in Low .. High => A (K) <= A (High));
   --  Ghost lemma (axiom) proving that the last element of a sorted array
   --  is its maximum.
   --
   --  Given that A (Low..High) is sorted in ascending order, this lemma
   --  establishes that every element in the range is less than or equal to
   --  A (High). This follows directly from the transitivity of <= across
   --  the sorted sequence.

   procedure Lemma_Insert_Preserves_Perm
     (Before : List;
      Insert : Index;
      Source : Index;
      After  : List)
   with
     Ghost,
     Import,
     Global => null,
     Pre  => Insert in Before'Range           and then
             Source in Before'Range           and then
             Insert <= Source                 and then
             After'First = Before'First       and then
             After'Last = Before'Last         and then
             After (Insert) = Before (Source) and then
             (for all K in Insert .. Index'Pred (Source) =>
                 After (Index'Succ (K)) = Before (K))
             and then
             (for all K in Before'Range =>
                (if K < Insert or K > Source then After (K) = Before (K))),
     Post => Permutation (Before, After);
   --  Ghost lemma (axiom) proving that the insertion sort shift-and-place
   --  operation preserves the permutation property.
   --
   --  Given that After is derived from Before by taking the element at
   --  position Source, shifting elements Insert..Pred(Source) right by one
   --  position, and placing the Source element at Insert, this lemma
   --  establishes that After is a permutation of Before. This is sound
   --  because every element in Before appears exactly once in After: the
   --  element from Source moves to Insert, each element from Insert through
   --  Pred(Source) moves one position right, and all other elements are
   --  unchanged.

   procedure Lemma_Perm_Preserves_Upper_Bound
     (Old_A, New_A : List;
      Low, High    : Index;
      Bound        : Element)
   with
     Ghost,
     Import,
     Global => null,
     Pre  => Low in Old_A'Range        and then
             High in Old_A'Range       and then
             Low in New_A'Range        and then
             High in New_A'Range       and then
             Old_A'First = New_A'First and then
             Old_A'Last = New_A'Last   and then
             (for all K in Low .. High => Old_A (K) <= Bound)
             and then
             Permutation (Old_A, New_A)
             and then
             (for all K in Old_A'Range =>
                (if K < Low or K > High then New_A (K) = Old_A (K))),
     Post => (for all K in Low .. High => New_A (K) <= Bound);
   --  Ghost lemma (axiom) proving that a permutation preserves an upper
   --  bound on all elements in a range.
   --
   --  Given that every element in Old_A (Low..High) is less than or equal
   --  to Bound, and New_A is a permutation of Old_A with elements outside
   --  Low..High unchanged, this lemma establishes that every element in
   --  New_A (Low..High) is also less than or equal to Bound. This is sound
   --  because a permutation only rearranges values without changing them,
   --  so any property that holds for every value in the multiset is
   --  preserved.

   procedure Lemma_Perm_Preserves_Lower_Bound
     (Old_A, New_A : List;
      Low, High    : Index;
      Bound        : Element)
   with
     Ghost,
     Import,
     Global => null,
     Pre  => Low in Old_A'Range        and then
            High in Old_A'Range        and then
             Low in New_A'Range        and then
             High in New_A'Range       and then
             Old_A'First = New_A'First and then
             Old_A'Last = New_A'Last   and then
             (for all K in Low .. High => Bound <= Old_A (K))
             and then
             Permutation (Old_A, New_A)
             and then
             (for all K in Old_A'Range =>
                (if K < Low or K > High then New_A (K) = Old_A (K))),
     Post => (for all K in Low .. High => Bound <= New_A (K));
   --  Ghost lemma (axiom) proving that a permutation preserves a lower
   --  bound on all elements in a range.
   --
   --  Given that every element in Old_A (Low..High) is greater than or
   --  equal to Bound, and New_A is a permutation of Old_A with elements
   --  outside Low..High unchanged, this lemma establishes that every
   --  element in New_A (Low..High) is also greater than or equal to Bound.
   --  This is sound because a permutation only rearranges values without
   --  changing them, so any property that holds for every value in the
   --  multiset is preserved.

   procedure Lemma_Perm_From_Both_Halves (A, B : List; Mid : Index) with
     Ghost,
     Import,
     Global => null,
     Pre  => A'First = B'First and then A'Last = B'Last and then
             Mid in A'Range and then Mid < A'Last and then
             Permutation (A (A'First .. Mid), B (B'First .. Mid)) and then
             Permutation (A (Index'Succ (Mid) .. A'Last),
                          B (Index'Succ (Mid) .. B'Last)),
     Post => Permutation (A, B);
   --  If each half of A is a permutation of the corresponding half of B,
   --  then A is a permutation of B.  Used to chain permutation through
   --  two independent recursive sorts of disjoint halves.
   --  Imported as an axiom because it requires the Occurrences_Split
   --  property which GNATprove cannot derive automatically.

end Sorting_Proof_Utils;
