--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof.gpr -j0 --output=oneline -u demo_time_stamp.adb --no-inlining --level=2

with Ada.Text_IO; use Ada.Text_IO;
with Time_Stamps; use Time_Stamps;

procedure Demo_Time_Stamp with SPARK_Mode is
   Stamp : Time_Stamp_Image;
   --  Time_Stamps.Now is a volatile function: its result must be captured into
   --  a variable before use, as a volatile call may not appear as an actual
   --  parameter.
begin
   Format := American;
   Stamp := Now;
   Put ("MM/DD/YYYY HH:MM:SS  ->  ");
   Put_Line (Stamp);

   Format := European;
   Stamp := Now;
   Put ("DD/MM/YYYY HH:MM:SS  ->  ");
   Put_Line (Stamp);
end Demo_Time_Stamp;
