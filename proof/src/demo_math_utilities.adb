--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Math_Utilities;
with Ada.Text_IO;  use Ada.Text_IO;

procedure Demo_Math_Utilities with SPARK_Mode is

   function Map is new Math_Utilities.Range_To_Domain_Mapping (Integer);

   Lower_Range  : constant := 0;
   Upper_Range  : constant := 20;
   Lower_Domain : constant := 0;
   Upper_Domain : constant := 4;

begin
   for K in Lower_Range .. Upper_Range loop
      Put_Line (K'Image & " : " & Map (K, Range_Min  => Lower_Range,  Range_Max  => Upper_Range,
                                          Domain_Min => Lower_Domain, Domain_Max => Upper_Domain)'Image);
   end loop;
end Demo_Math_Utilities;
