--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides lemmas for proving permutations of lists of
--  arbitrary types.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with SPARK.Big_Integers;   use SPARK.Big_Integers;
with SPARK.Containers.Functional.Multisets;

generic
   type Element is private;
   type Index is (<>);
   type List is array (Index range <>) of Element;
   with package Element_Multisets is new SPARK.Containers.Functional.Multisets (Element, "=");
package Permutation_Utils with
  SPARK_Mode,
  Always_Terminates
is
   use Element_Multisets;

   function Occurrences (Values : List; Last : Index'Base) return Multiset is
     (if Last < Values'First then Empty_Multiset
      else Add (Occurrences (Values, Index'Pred (Last)), Values (Last)))
   with
     Ghost,
     Subprogram_Variant => (Decreases => Last),
     Pre => Last <= Values'Last;

   function Occurrences (Values : List) return Multiset is
     (if Values'Length = 0 then Empty_Multiset else Occurrences (Values, Values'Last))
   with Ghost;

   function Permutation (Left, Right : List) return Boolean is
     (Left'Length = Right'Length and then Occurrences (Left) = Occurrences (Right))
   with Ghost;

   function Occurrence_Count (Values : List; N : Element) return Big_Natural is
     (Element_Multisets.Nb_Occurence (Occurrences (Values), N))
   with Ghost;

   function Is_Replaced_At (A : List; K : Index; Value : Element; R : List) return Boolean is
     (R'First = A'First and then R'Last = A'Last
      and then R (K) = Value
      and then (for all J in A'Range => (if K /= J then R (J) = A (J))))
   with
     Ghost,
     Pre => K in A'Range;
   --  Verifies that the contents of R equal those of A, except at index K, in
   --  which case R (K) = Value

   procedure Lemma_Occurrences_After_Replace
     (A     : List;
      K     : Index;
      Value : Element;
      R     : List)
   with
     Ghost,
     Import,
     Pre    => K in A'Range and then Is_Replaced_At (A, K, Value, R),
     Post   => (if Value = A (K) then
                  Occurrences (R) = Occurrences (A)
                else
                  Occurrence_Count (R, Value) = Occurrence_Count (A, Value) + 1 and then
                  Occurrence_Count (R, A (K)) = Occurrence_Count (A, A (K)) - 1 and then
                  (for all E of Union (Occurrences (R), Occurrences (A)) =>
                     (if E not in Value | A (K) then Occurrence_Count (R, E) = Occurrence_Count (A, E)))),
     Global => null;
   --  Ghost lemma (axiom) describing how element occurrence counts change
   --  when a single array element is replaced.
   --
   --  Given that R is identical to A except at index K where R(K) = Value,
   --  this lemma establishes the effect on occurrence counts: if Value equals
   --  A(K), the replacement is a no-op and occurrences are unchanged. Otherwise,
   --  the count of Value increases by one, the count of A(K) decreases by one,
   --  and all other element counts remain the same. This is the fundamental
   --  building block for reasoning about how array mutations affect multiset
   --  membership. Imported as an axiom because GNATprove cannot connect the
   --  recursive definition of Occurrences with pointwise array modification.

   procedure Lemma_Perm_Transitivity (A, B, C : List) with
     Ghost,
     Pre    => Permutation (A, B) and then Permutation (B, C),
     Post   => Permutation (A, C),
     Global => null;
   --  Ghost lemma (axiom) establishing transitivity of the permutation relation.
   --
   --  If array A is a permutation of array B, and array B is a permutation
   --  of array C, then array A is a permutation of array C. This is a
   --  fundamental property of equivalence relations and is used throughout
   --  the verification to chain permutation proofs across multiple
   --  transformations of the array.

   procedure Lemma_Perm_Preserved_After_Swapping
     (Before : List;
      I, J   : Index;
      After  : List)
 with
   Ghost,
   Import,
   Global => null,
   Pre  => I in Before'Range
           and then J in Before'Range
           and then After'First = Before'First
           and then After'Last = Before'Last
           and then After (I) = Before (J)
           and then After (J) = Before (I)
           and then (for all K in Before'Range =>
                       (if K /= I and then K /= J then After (K) = Before (K))),
   Post => Permutation (Before, After);
   --  Ghost lemma (axiom) proving that swapping two elements preserves the
   --  permutation property.
   --
   --  Given that After is identical to Before except that the elements at
   --  positions I and J have been exchanged, this lemma establishes that
   --  After is a permutation of Before. This is sound because swapping two
   --  elements never changes the multiset of values in the array: every
   --  element that was present before the swap is still present afterward,
   --  with the same number of occurrences. Imported as an axiom because
   --  proving it requires multiset extensionality reasoning beyond automated
   --  theorem provers.

end Permutation_Utils;
