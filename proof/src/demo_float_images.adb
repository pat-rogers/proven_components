--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Floating_Point_Images;

with Ada.Numerics;       use Ada.Numerics;
with Ada.Text_IO;        use Ada.Text_IO;

procedure Demo_Float_Images with SPARK_Mode is

   type Real is digits 12;

   package Test is new Floating_Point_Images (Real);
   use Test;

begin
   Put_line (Image (Pi));

   Put_Line ("[0.0]        :" & Real'(0.0)'Image);
   Put_Line ("[0.05]       :" & Real'(0.05)'Image);
   Put_Line ("[10.0]       :" & Real'(10.0)'Image);
   Put_Line ("[0.00001]    :" & Real'(0.00001)'Image);
   Put_Line ("[Real'First] :" & Real'(Real'First)'Image);
   Put_Line ("[Real'Last]  :" & Real'(Real'Last)'Image);

   Put_Line ("----");

   Put_Line ("[0.0]        :" & Image (0.0));
   Put_Line ("[0.05]       :" & Image (0.05));
   Put_Line ("[10.0]       :" & Image (10.0));
   Put_Line ("[0.00001]    :" & Image (0.00001));
   Put_Line ("[Real'First] :" & Image (Real'First));
   Put_Line ("[Real'Last]  :" & Image (Real'Last));

   Put_Line ("Done");
end Demo_Float_Images;
