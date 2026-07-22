--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  Unit test harness for the generic package Uniform_Distribution. Exercises
--  the client-facing Scaled_Uniform_Random wrapper and the underlying
--  Scaled_To_Range kernel through Float instances, reporting a PASS/FAIL line
--  per check and a final summary.
--
--  This is a test harness, not a proof target, so it is SPARK_Mode => Off:
--  Scaled_Uniform_Random draws from an Ada.Numerics.Float_Random generator,
--  whose use is not valid in SPARK.

with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Uniform_Distribution;

procedure Uniform_Distribution_Tests with SPARK_Mode => Off is

   use Ada.Numerics;

   Tolerance : constant Float := 1.0E-5;
   --  Float carries roughly seven significant digits; each exact-case kernel
   --  result is reached in a few operations, so it stays within this margin.

   Checks_Run    : Natural := 0;
   Checks_Failed : Natural := 0;

   Gen : Float_Random.Generator;
   --  Drives Scaled_Uniform_Random. Left unseeded so the generated sequence,
   --  and hence this test, is reproducible from run to run.

   function Scaled is new Uniform_Distribution.Scaled_To_Range (Float);
   function Uniform_Random is new Uniform_Distribution.Scaled_Uniform_Random (Float, Gen);

   procedure Check (Description : String;  Condition : Boolean);
   --  Records the outcome of a single check and prints one result line.

   procedure Test_Scaled_To_Range_Endpoints;
   --  The kernel maps 0.0 to Lower and 1.0 to Upper.

   procedure Test_Scaled_To_Range_Midpoint;
   --  The kernel maps 0.5 to the midpoint of the range.

   procedure Test_Scaled_To_Range_Clamps;
   --  Inputs outside 0.0 .. 1.0 are clamped, keeping the result within range.

   procedure Test_Uniform_Random_Within_Range;
   --  Every Scaled_Uniform_Random sample lies within Lower .. Upper.

   procedure Test_Uniform_Random_Mean;
   --  Over many samples the mean approximates the midpoint of the range.

   -----------
   -- Check --
   -----------

   procedure Check (Description : String;  Condition : Boolean) is
   begin
      Checks_Run := Checks_Run + 1;
      if Condition then
         Put_Line ("PASS: " & Description);
      else
         Checks_Failed := Checks_Failed + 1;
         Put_Line ("FAIL: " & Description);
      end if;
   end Check;

   ------------------------------------
   -- Test_Scaled_To_Range_Endpoints --
   ------------------------------------

   procedure Test_Scaled_To_Range_Endpoints is
      Lower : constant Float := 1.0;
      Upper : constant Float := 3.0;
   begin
      Check ("Scaled_To_Range maps 0.0 to Lower",
             abs (Scaled (0.0, Lower, Upper) - Lower) <= Tolerance);
      Check ("Scaled_To_Range maps 1.0 to Upper",
             abs (Scaled (1.0, Lower, Upper) - Upper) <= Tolerance);
   end Test_Scaled_To_Range_Endpoints;

   -----------------------------------
   -- Test_Scaled_To_Range_Midpoint --
   -----------------------------------

   procedure Test_Scaled_To_Range_Midpoint is
      Lower : constant Float := 1.0;
      Upper : constant Float := 3.0;
   begin
      Check ("Scaled_To_Range maps 0.5 to the midpoint of the range",
             abs (Scaled (0.5, Lower, Upper) - 2.0) <= Tolerance);
   end Test_Scaled_To_Range_Midpoint;

   ---------------------------------
   -- Test_Scaled_To_Range_Clamps --
   ---------------------------------

   procedure Test_Scaled_To_Range_Clamps is
      Lower : constant Float := 1.0;
      Upper : constant Float := 3.0;
   begin
      Check ("Scaled_To_Range clamps a negative input to Lower",
             abs (Scaled (-4.0, Lower, Upper) - Lower) <= Tolerance);
      Check ("Scaled_To_Range clamps an above-one input to Upper",
             abs (Scaled (5.0, Lower, Upper) - Upper) <= Tolerance);
   end Test_Scaled_To_Range_Clamps;

   ---------------------------------------
   -- Test_Uniform_Random_Within_Range --
   ---------------------------------------

   procedure Test_Uniform_Random_Within_Range is
      Lower    : constant Float := 1.0;
      Upper    : constant Float := 3.0;
      Sample   : Float;
      Violated : Boolean := False;
   begin
      for Trial in 1 .. 100_000 loop
         Sample := Uniform_Random (Lower, Upper);
         if Sample < Lower or else Sample > Upper then
            Violated := True;
         end if;
      end loop;
      Check ("Scaled_Uniform_Random stays within Lower .. Upper", not Violated);
   end Test_Uniform_Random_Within_Range;

   ------------------------------
   -- Test_Uniform_Random_Mean --
   ------------------------------

   procedure Test_Uniform_Random_Mean is
      Samples   : constant := 200_000;
      Lower     : constant Float := 1.0;
      Upper     : constant Float := 3.0;
      Mean_Tol  : constant Float := 0.02;
      Total     : Float := 0.0;
   begin
      for Trial in 1 .. Samples loop
         Total := Total + Uniform_Random (Lower, Upper);
      end loop;
      Check ("Scaled_Uniform_Random mean approximates the midpoint of the range",
             abs (Total / Float (Samples) - 2.0) <= Mean_Tol);
   end Test_Uniform_Random_Mean;

begin
   Put_Line ("Running Uniform_Distribution unit tests");
   Put_Line ("---------------------------------------");

   Test_Scaled_To_Range_Endpoints;
   Test_Scaled_To_Range_Midpoint;
   Test_Scaled_To_Range_Clamps;
   Test_Uniform_Random_Within_Range;
   Test_Uniform_Random_Mean;

   New_Line;
   Put_Line ("Checks run:    " & Checks_Run'Image);
   Put_Line ("Checks failed: " & Checks_Failed'Image);

   if Checks_Failed = 0 then
      Put_Line ("Result: ALL TESTS PASSED");
   else
      Put_Line ("Result: FAILURES DETECTED");
   end if;
end Uniform_Distribution_Tests;
