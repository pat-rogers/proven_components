--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof.gpr -j0 --output=oneline -u demo_sorts.adb --no-inlining --level=2

with Ada.Text_IO;       use Ada.Text_IO;
with Character_Sorting; use Character_Sorting;

procedure Demo_Sorts with SPARK_Mode is
   Unsorted_Value : constant String := "ZXKFCYASVLGNHIPMQURDBWEOTJ";
   Data : String := Unsorted_Value;
begin
   Put_Line ("Straight_Selection");
   Data := Unsorted_Value;
   pragma Assert (not Sorted_Ascending (Data));
   Put_Line (Data);
   Straight_Selection (Data);
   pragma Assert (Sorted_Ascending (Data));
   Put_Line (Data);

   Put_Line ("Straight_Insertion");
   Data := Unsorted_Value;
   pragma Assert (not Sorted_Ascending (Data));
   Put_Line (Data);
   Straight_Insertion (Data);
   pragma Assert (Sorted_Ascending (Data));
   Put_Line (Data);

   Put_Line ("Quicksort");
   Data := Unsorted_Value;
   pragma Assert (not Sorted_Ascending (Data));
   Put_Line (Data);
   Quicksort (Data);
   pragma Assert (Sorted_Ascending (Data));
   Put_Line (Data);
end Demo_Sorts;
