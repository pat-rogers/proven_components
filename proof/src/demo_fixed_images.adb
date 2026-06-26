--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Fixed_Point_Images;
with Ada.Text_IO;  use Ada.Text_IO;

procedure Demo_Fixed_Images with SPARK_Mode is

   type Fixed is delta 0.01 range -1000.0 .. 1000.0;
   for Fixed'Small use 0.01;  -- decimal Small so 0.01 multiples are exact

   package Images is new Fixed_Point_Images (Fixed);
   use Images;

begin
   Put_Line ("[0.0]          :" & Image (0.0));
   Put_Line ("[3.14]         :" & Image (3.14));
   Put_Line ("[-3.14]        :" & Image (-3.14));
   Put_Line ("[3.14 blank]   :" & Image (3.14, Leading_Blank => True));
   Put_Line ("[Fixed'First]  :" & Image (Fixed'First));
   Put_Line ("[Fixed'Last]   :" & Image (Fixed'Last));

   Put_Line ("----");

   Put_Line ("[Frac 0.25, 5] :" & Fractional_Image (0.25, 5));
   Put_Line ("[Frac 0.5,  1] :" & Fractional_Image (0.5,  1));

   Put_Line ("Done");
end Demo_Fixed_Images;
