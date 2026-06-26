--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Sort_Routines with SPARK_Mode is

   use Element_Permutations;
   use Element_Sorting_Utils;

   ---------------------
   -- Swap_Components --
   ---------------------

   procedure Swap_Components (This : in out List; I, J : Index) with
     Inline,
     Pre  => I in This'Range and then
             J in This'Range,
     Post => This (I) = This'Old (J) and then
             This (J) = This'Old (I) and then
             (for all K in This'Range =>
                (if K /= I and then K /= J then This (K) = This'Old (K)))
             and then Permutation (This'Old, This),
     Global => null;
   --  Exchanges the elements at positions I and J in the array.
   --
   --  The postcondition ensures that:
   --   - The element previously at I is now at J
   --   - The element previously at J is now at I
   --   - All other elements remain in their original positions
   --   - The operation preserves the multiset of elements (permutation)

   ---------------------------------
   -- Index_for_Minimum_Component --
   ---------------------------------

   function Index_for_Minimum_Component
     (This : List;
      From : Index;
      To   : Index)
   return Index
   with
     Pre => From in This'Range and then
            To in This'Range  and then
            From <= To,
     Post => Index_for_Minimum_Component'Result in From .. To and then
             (for all J in From .. To =>
                This (Index_for_Minimum_Component'Result) <= This (J));
   --  Returns the index corresponding to the least component value of This
   --  within the slice This (From..To), and the result is in the range From..To

   ----------------------------
   -- Median_Of_Three_Pivot --
   ----------------------------

   procedure Median_Of_Three_Pivot
     (This : in out List;
      Low  : Index;
      High : Index)
   with
     Pre  => Low in This'Range and then
             High in This'Range and then
             Low < High and then
             Index'Pos (High) in Integer'Range and then
             Index'Pos (Low) in Integer'Range,
     Post => Permutation (This'Old, This) and then
             (for all K in This'Range =>
                (if K < Low or K > High then This (K) = This'Old (K)))
             and then This (Low) <= This (High),
     Global => null;
   --  Selects the median of {This(Low), This(Mid), This(High)} and places
   --  it at This(Low) so that Partition_Around_Pivot (Hoare) uses it as pivot.
   --  The maximum of the three is placed at This(High), serving as a sentinel
   --  to bound the left scan in the Hoare partition.
   --  Only elements within Low..High are touched; the frame condition is
   --  preserved.

   ----------------------------
   -- Partition_Around_Pivot --
   ----------------------------

   procedure Partition_Around_Pivot
     (This      : in out List;
      Low       : Index;
      High      : Index;
      Pivot_Pos : out Index)
   with
     Pre  => Low in This'Range and then
             High in This'Range and then
             Low < High and then
             Index'Pos (Low)  in Integer'Range and then
             Index'Pos (High) in Integer'Range and then
             This (Low) <= This (High),
     Post => Pivot_Pos in Low .. Index'Pred (High) and then
             (for all K in Low .. Pivot_Pos =>
                This (K) <= This'Old (Low))
             and then
             (for all K in Index'Succ (Pivot_Pos) .. High =>
                This'Old (Low) <= This (K))
             and then Permutation (This'Old, This)
             and then
             (for all K in This'Range =>
                (if K < Low or K > High then This (K) = This'Old (K))),
     Global => null;
   --  Partitions the array segment around a pivot using Hoare's algorithm.
   --
   --  The pivot value is This(Low) (the median placed there by
   --  Median_Of_Three_Pivot). Two pointers I and J scan inward from Low and
   --  High respectively, swapping out-of-place elements, until they cross.
   --  The returned Pivot_Pos is the split index J, which is strictly less
   --  than High (guaranteed by the sentinel This(High) >= pivot).
   --
   --  Postconditions guarantee:
   --   - Pivot_Pos is strictly within Low .. Pred(High), so both recursive
   --     subproblems are strictly smaller (termination)
   --   - All elements in Low .. Pivot_Pos are <= the pivot value
   --   - All elements in Succ(Pivot_Pos) .. High are >= the pivot value
   --   - The operation is a permutation (no elements added or removed)
   --   - Elements outside Low .. High remain unchanged (frame condition)

   ------------------------------
   -- Recursive_Sort_Partition --
   ------------------------------

   procedure Recursive_Sort_Partition (This : in out List; Low, High : Index) with
     Pre  => Low in This'Range and then
             High in This'Range and then
             Low <= High and then
             Index'Pos (Low) in Integer'Range and then
             Index'Pos (High) in Integer'Range,
     Post => Sorted_Ascending (This (Low .. High)) and then
             Permutation (This'Old, This) and then
             (for all K in This'Range =>
                (if K < Low or K > High then This (K) = This'Old (K))),
     Subprogram_Variant =>
       (Decreases => Index'Pos (High) - Index'Pos (Low)),
     Global => null;
   --  Recursive implementation of the Quicksort algorithm with Hoare partitioning.
   --
   --  Sorts the segment This (Low..High) in ascending order using the divide-and-
   --  conquer strategy:
   --   1. Select a pivot via median-of-three
   --   2. Partition the array around the pivot
   --   3. Recursively sort the left partition (elements < pivot)
   --   4. Recursively sort the right partition (elements > pivot)
   --
   --  The algorithm terminates when Low >= High (base case: 0 or 1 element).
   --  Termination is proven via the subprogram variant, which shows that each
   --  recursive call reduces the range size.
   --
   --  Postconditions guarantee:
   --   - The segment Low..High is sorted in ascending order
   --   - The operation is a permutation (same elements, possibly reordered)
   --   - Elements outside Low..High remain unchanged (frame condition)
   --   - Index positions remain in valid integer range (overflow safety)

   ------------------------
   -- Straight_Selection --
   ------------------------

   procedure Straight_Selection (This : in out List) is
      Min_Idx       : Index;
      This_On_Entry : constant List := This with Ghost;
      Before_Swap   : List := This with Ghost;
   begin
      if This'Length <= 1 then
         return;
      end if;

      for I in This'Range loop
         --  Find the index of the minimum element in the unsorted tail
         Min_Idx := Index_For_Minimum_Component (This, From => I, To => This'Last);

         --  Capture state before swap for transitivity and frame reasoning
         Before_Swap := This;
         --  Place the minimum element at position I
         Swap_Components (This, I, Min_Idx);
         --  Chain permutation: original -> before swap -> after swap
         Lemma_Perm_Transitivity (This_On_Entry, Before_Swap, This);

         if I > This'First then
            --  The swap only touched positions >= I, so the prefix is unchanged
            Lemma_Sorted_Frame (Before_Swap, This, This'First, Index'Pred (I));
            --  The new element at I is the tail minimum, and the previous
            --  iteration placed the previous tail minimum at Pred(I), so
            --  the boundary is ordered
            pragma Assert (This (Index'Pred (I)) <= This (I));
            --  Combine the sorted prefix with the new element to extend sortedness
            Lemma_Sorted_Concat (This, This'First, Index'Pred (I), I);
         end if;

         --  Every placed element is <= every remaining element
         pragma Loop_Invariant
           (for all K in This'First .. I =>
              (for all J in I .. This'Last =>
                   This (K) <= This (J)));

         pragma Loop_Invariant (Permutation (This_On_Entry, This));
         pragma Loop_Invariant (Sorted_Ascending (This (This'First .. I)));
      end loop;
   end Straight_Selection;

   ------------------------
   -- Straight_Insertion --
   ------------------------

   procedure Straight_Insertion (This : in out List) is
      Key          : Element;
      Insert       : Index;
      Loop_Entry_0 : constant List := This with Ghost;
      Loop_Entry   : List := This with Ghost;
   begin
      if This'Length <= 1 then
         return;
      end if;

      for I in Index'Succ (This'First) .. This'Last loop
         Loop_Entry := This;
         Key := This (I);
         Insert := I;

         --  Shift elements right until we find the insertion point for Key
         while Insert > This'First and then This (Index'Pred (Insert)) > Key loop
            This (Insert) := This (Index'Pred (Insert));
            Insert := Index'Pred (Insert);

            pragma Loop_Variant (Decreases => Index'Pos (Insert));

            --  Insert is within the sorted prefix
            pragma Loop_Invariant
              (Insert in This'First .. Index'Pred (I));
            --  Elements Insert..Pred(I) have been shifted right by one
            pragma Loop_Invariant
              (for all K in Insert .. Index'Pred (I) =>
                   This (Index'Succ (K)) = Loop_Entry (K));
            --  Everything outside Insert..I is unchanged from Loop_Entry
            pragma Loop_Invariant
              (for all K in This'Range =>
                 (if K < Insert or K > I then This (K) = Loop_Entry (K)));
            --  All shifted elements are strictly greater than the key
            pragma Loop_Invariant
              (for all K in Index'Succ (Insert) .. I =>
                   Key < This (K));
         end loop;

         --  Place the key at the insertion point, completing the rotation
         --  of the sub-array Insert..I
         This (Insert) := Key;

         Lemma_Insert_Preserves_Perm (Loop_Entry, Insert, I, This);
         Lemma_Perm_Transitivity (Loop_Entry_0, Loop_Entry, This);

         --  Establish sortedness of the prefix before Insert
         if Insert > This'First then
            Lemma_Sorted_Subrange
              (Loop_Entry, This'First, Index'Pred (I),
               This'First, Index'Pred (Insert));
            Lemma_Sorted_Frame (Loop_Entry, This, This'First, Index'Pred (Insert));
         end if;

         --  Establish sortedness of the shifted region after Insert
         if Insert < I then
            Lemma_Sorted_Subrange
              (Loop_Entry, This'First, Index'Pred (I),
               Insert, Index'Pred (I));
            Lemma_Sorted_Shift_Right (Loop_Entry, This, Insert, Index'Pred (I));
         end if;

         --  Build up sortedness left to right through Insert
         if Insert > This'First then
            Lemma_Sorted_Max (This, This'First, Index'Pred (Insert));
            Lemma_Sorted_Concat (This, This'First, Index'Pred (Insert), Insert);
         end if;

         if Insert < I then
            Lemma_Sorted_Max (This, This'First, Insert);
            Lemma_Sorted_Concat (This, This'First, Insert, I);
         end if;

         pragma Loop_Invariant (Permutation (Loop_Entry_0, This));
         pragma Loop_Invariant (Sorted_Ascending (This (This'First .. I)));
      end loop;
   end Straight_Insertion;

   ----------------------------
   -- Median_Of_Three_Pivot --
   ----------------------------

   procedure Median_Of_Three_Pivot
     (This      : in out List;
      Low, High : Index)
   is
      This_On_Entry : constant List := This with Ghost;
   begin
      --  Fewer than 3 elements: only the 2-element case can violate the
      --  postcondition This(Low) <= This(High).  Sort it explicitly.
      if Index'Pos (High) - Index'Pos (Low) < 2 then
         if This (High) < This (Low) then
            Swap_Components (This, Low, High);
            Lemma_Perm_Transitivity (This_On_Entry, This_On_Entry, This);
            --  Swap_Components postcondition gives Permutation(This_On_Entry, This)
            --  directly; the transitivity call is kept so GNATprove can chain
            --  the permutation proof uniformly on both branches.
         end if;
         pragma Assert (This (Low) <= This (High));
         return;
      end if;

      declare
         Mid         : constant Index := Midpoint (Low, High);
         After_Step1 : List := This with Ghost;
         After_Step2 : List := This with Ghost;
      begin
         --  Step 1: ensure This(Low) <= This(Mid)
         if This (Mid) < This (Low) then
            Swap_Components (This, Low, Mid);
         end if;
         pragma Assert (This (Low) <= This (Mid));
         After_Step1 := This;

         --  Step 2: ensure This(Mid) <= This(High).
         --  After this step This(High) is the maximum of the original three.
         if This (High) < This (Mid) then
            Swap_Components (This, Mid, High);
         end if;
         pragma Assert (This (Mid) <= This (High));
         Lemma_Perm_Transitivity (This_On_Entry, After_Step1, This);
         After_Step2 := This;

         --  This(High) is now the maximum; This(Low) <= This(Mid) from step 1,
         --  and This(Mid) <= This(High) from step 2, so the sentinel holds.
         pragma Assert (This (Low) <= This (High));

         --  Step 3: move the median to This(Low) so Hoare partition uses it
         --  as the pivot, while This(High) stays as the sentinel.
         if This (Low) < This (Mid) then
            Swap_Components (This, Low, Mid);
            Lemma_Perm_Transitivity (This_On_Entry, After_Step2, This);
         end if;

         pragma Assert (This (Low) <= This (High));
      end;
   end Median_Of_Three_Pivot;

   ----------------------------
   -- Partition_Around_Pivot --
   ----------------------------

   procedure Partition_Around_Pivot
     (This      : in out List;
      Low       : Index;
      High      : Index;
      Pivot_Pos : out Index)
   is
      Pivot         : constant Element := This (Low);
      This_On_Entry : constant List := This with Ghost;
      I             : Index := Low;
      J             : Index := High;
   begin
      Pivot_Pos := Low;

      --  Sentinel established by Median_Of_Three_Pivot: This(High) >= Pivot.
      pragma Assert (Pivot <= This (High));

      while I < J loop
         pragma Loop_Variant
           (Decreases => Index'Pos (High) - Index'Pos (I));

         pragma Loop_Invariant
           --  Pivot_Pos stays in valid range (initialized to Low before loop).
           (Pivot_Pos in Low .. Index'Pred (High) and then
            --  Sentinel preserved: pivot <= This(High) survives swaps.
            --  If swap at J=High: new This(High) = old This(I) > Pivot (left scan stopped there).
            --  If swap at J<High: This(High) unchanged, still >= Pivot from prior.
            This_On_Entry (Low) <= This (High) and then
            I in Low .. High and then
            J in Low .. High and then
            --  Left partition classified: all elements before I are <= Pivot.
            (for all K in Low .. Index'Pred (I) =>
               This (K) <= This_On_Entry (Low))
            and then
            --  Right partition classified: elements strictly after J are >= Pivot.
            --  Guarded against Index'Succ overflow when J = Index'Last.
            (J = Index'Last or else
               (for all K in Index'Succ (J) .. High =>
                  This_On_Entry (Low) <= This (K)))
            and then
            --  When I = Low no swap has occurred so This is unchanged.
            (if I = Low then This = This_On_Entry)
            and then
            --  Elements outside Low..High are unchanged.
            (for all K in This'Range =>
               (if K < Low or else K > High then This (K) = This_On_Entry (K)))
            and then
            Permutation (This_On_Entry, This));

         --  Advance I rightward past elements <= Pivot.
         while I < J and then This (I) <= Pivot loop
            I := Index'Succ (I);
            pragma Loop_Variant (Decreases => Index'Pos (J) - Index'Pos (I));
            pragma Loop_Invariant
              (I in Low .. J and then
               (for all K in Low .. Index'Pred (I) =>
                  This (K) <= This_On_Entry (Low)));
         end loop;

         --  Retreat J leftward past elements > Pivot.
         while I < J and then Pivot < This (J) loop
            J := Index'Pred (J);
            pragma Loop_Variant (Decreases => Index'Pos (J) - Index'Pos (Low));
            pragma Loop_Invariant
              (J in Low .. High and then
               (for all K in Index'Succ (J) .. High =>
                  This_On_Entry (Low) <= This (K)));
         end loop;

         if I < J then
            Swap_Components (This, I, J);
            I := Index'Succ (I);
            J := Index'Pred (J);
         end if;
      end loop;

      pragma Assert (I > Low);

      if This (J) <= Pivot then
         --  J stopped on element <= Pivot.
         if J = High then
            --  Degenerate: This(High) = Pivot (since This(High) >= Pivot from
            --  precondition and This(J=High) <= Pivot). Use Pred(High) as pivot pos.
            --  Left: Low..Pred(High). I >= J = High, so I = High, Pred(I) = Pred(High).
            --  Left invariant covers Low..Pred(I) = Low..Pred(High).
            --  Right: High. This(High) = Pivot, and Pivot <= This(High).
            Pivot_Pos := Index'Pred (High);
            pragma Assert
              (for all K in Low .. Pivot_Pos =>
                 This (K) <= This_On_Entry (Low));
            pragma Assert
              (for all K in Index'Succ (Pivot_Pos) .. High =>
                 This_On_Entry (Low) <= This (K));
         else
            Pivot_Pos := J;
            pragma Assert
              (for all K in Low .. Pivot_Pos =>
                 This (K) <= This_On_Entry (Low));
            pragma Assert
              (for all K in Index'Succ (Pivot_Pos) .. High =>
                 This_On_Entry (Low) <= This (K));
         end if;

      else
         --  This(J) > Pivot: left scan stopped on element at I.
         --  I > Low (asserted above): I > Index'First, so Index'Pred(I) is safe.
         Pivot_Pos := Index'Pred (I);
         pragma Assert
           (for all K in Low .. Pivot_Pos =>
              This (K) <= This_On_Entry (Low));
         pragma Assert (This_On_Entry (Low) <= This (I));
         pragma Assert
           (for all K in Index'Succ (Pivot_Pos) .. High =>
              This_On_Entry (Low) <= This (K));
      end if;
   end Partition_Around_Pivot;

   ------------------------------
   -- Recursive_Sort_Partition --
   ------------------------------

   procedure Recursive_Sort_Partition (This : in out List; Low, High : Index) is
      Pivot_Pos     : Index;
      Pivot_Val     : Element with Ghost;
      This_On_Entry : constant List := This with Ghost;
      After_Median  : List := This with Ghost;
   begin
      if Low >= High then
         return;
      end if;

      Median_Of_Three_Pivot (This, Low, High);
      After_Median := This;

      --  Capture the pivot value (This(Low) after median selection) before
      --  the partition call modifies This.
      Pivot_Val := This (Low);

      Partition_Around_Pivot (This, Low, High, Pivot_Pos);

      --  Chain permutation: This_On_Entry -> After_Median -> This (post-partition)
      Lemma_Perm_Transitivity (This_On_Entry, After_Median, This);

      --  Partition postcondition gives:
      --   for all K in Low .. Pivot_Pos:        This(K) <= Pivot_Val
      --   for all K in Succ(Pivot_Pos) .. High: Pivot_Val <= This(K)
      --  Pivot_Pos is in Low .. Pred(High), so both sub-ranges are smaller.

      --  Sort the left partition: Low .. Pivot_Pos
      declare
         Before_Left : constant List := This with Ghost;
      begin
         Recursive_Sort_Partition (This, Low, Pivot_Pos);

         Lemma_Perm_Preserves_Upper_Bound
           (Before_Left, This, Low, Pivot_Pos, Pivot_Val);

         Lemma_Perm_Transitivity (This_On_Entry, Before_Left, This);
      end;

      pragma Assert (Sorted_Ascending (This (Low .. Pivot_Pos)));

      --  Sort the right partition: Succ(Pivot_Pos) .. High
      declare
         Before_Right : constant List := This with Ghost;
      begin
         Recursive_Sort_Partition (This, Index'Succ (Pivot_Pos), High);

         Lemma_Sorted_Frame (Before_Right, This, Low, Pivot_Pos);

         Lemma_Perm_Preserves_Lower_Bound
           (Before_Right, This, Index'Succ (Pivot_Pos), High, Pivot_Val);

         Lemma_Perm_Transitivity (This_On_Entry, Before_Right, This);
      end;

      --  Connect the two sorted halves via the pivot value bound.
      --  This(Pivot_Pos) = max of Low..Pivot_Pos <= Pivot_Val
      --                 <= min of Succ(Pivot_Pos)..High = This(Succ(Pivot_Pos))
      pragma Assert (for all K in Index'Succ (Pivot_Pos) .. High =>
                       This (Pivot_Pos) <= This (K));

      Lemma_Sorted_Max (This, Low, Pivot_Pos);
      Lemma_Sorted_Concat (This, Low, Pivot_Pos, High);
   end Recursive_Sort_Partition;

   ---------------
   -- Quicksort --
   ---------------

   procedure Quicksort (This : in out List) is
   begin
      if This'Length <= 1 then
         return;
      end if;
      Recursive_Sort_Partition (This, This'First, This'Last);
   end Quicksort;

   ---------------------
   -- Swap_Components --
   ---------------------

   procedure Swap_Components (This : in out List; I, J : Index) is
      Old_This : constant List := This with Ghost;
      Old_I    : constant Element := This (I);
   begin
      This (I) := This (J);
      This (J) := Old_I;

      Lemma_Perm_Preserved_After_Swapping (Old_This, I, J, This);
   end Swap_Components;

   ---------------------------------
   -- Index_for_Minimum_Component --
   ---------------------------------

   function Index_for_Minimum_Component
     (This : List;
      From : Index;
      To   : Index)
   return Index
   is
      Result : Index := From;
   begin
      for K in From .. To loop
         if This (K) < This (Result) then
            Result := K;
         end if;
         pragma Loop_Invariant
           (Result in From .. To and then
            (for all J in From .. K => This (Result) <= This (J)));
      end loop;
      return Result;
   end Index_for_Minimum_Component;

end Sort_Routines;
