--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Sorting_Proof_Utils is

   ----------------------
   -- Lemma_Sorted_Max --
   ----------------------

   procedure Lemma_Sorted_Max
     (A : List; Low, High : Index)
   is
   begin
      for K in Low .. High loop
         pragma Loop_Invariant
           (for all J in Low .. K => A (J) <= A (K));
      end loop;
   end Lemma_Sorted_Max;

   ---------------------------
   -- Lemma_Sorted_Subrange --
   ---------------------------

   procedure Lemma_Sorted_Subrange
     (A : List;
      Low, High, New_Low, New_High : Index)
   is null;
   --  A sub-range (effectively a slice) of a sorted array is sorted

   ------------------------
   -- Lemma_Sorted_Frame --
   ------------------------

   procedure Lemma_Sorted_Frame
     (Old_A : List;
      New_A : List;
      Low   : Index;
      High  : Index)
   is
      pragma Unreferenced (Old_A);
   begin
      null;
   end Lemma_Sorted_Frame;

   ------------------------------
   -- Lemma_Sorted_Shift_Right --
   ------------------------------

   procedure Lemma_Sorted_Shift_Right
     (Old_A    : List;
      New_A    : List;
      Old_Low  : Index;
      Old_High : Index)
   is
      pragma Unreferenced (Old_A);
   begin
      for K in Old_Low .. Old_High loop
         pragma Loop_Invariant
           (for all J in Index'Succ (Old_Low) .. Index'Succ (K) =>
              (for all L in Index'Succ (Old_Low) .. Index'Pred (J) =>
                 New_A (L) <= New_A (J)));
      end loop;
   end Lemma_Sorted_Shift_Right;

   -------------------------
   -- Lemma_Sorted_Concat --
   -------------------------

   procedure Lemma_Sorted_Concat
     (A : List; Low, Mid, High : Index)
   is
   begin
      if Mid = High then
         return;
      end if;
      for J in Index'Succ (Mid) .. High loop
         Lemma_Sorted_Max (A, Low, Mid);
         pragma Loop_Invariant
           (for all K in Low .. J =>
              (for all L in Low .. Index'Pred (K) =>
                 A (L) <= A (K)));
      end loop;
   end Lemma_Sorted_Concat;

end Sorting_Proof_Utils;
