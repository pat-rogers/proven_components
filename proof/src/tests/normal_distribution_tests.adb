--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  Unit test harness for the generic package Normal_Distribution. Exercises
--  the client-facing Gaussian_Random wrapper and the underlying Gaussian_Deviate
--  kernel through Float instances, reporting a PASS/FAIL line per check and a
--  final summary.
--
--  This is a test harness, not a proof target, so it is SPARK_Mode => Off:
--  Gaussian_Random draws from an Ada.Numerics.Float_Random generator, whose use
--  is not valid in SPARK.
--
--  The statistical checks assert the mean, symmetry, and standard deviation of
--  the samples against Mu and Sigma.

with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;
with Normal_Distribution;

procedure Normal_Distribution_Tests with SPARK_Mode => Off is

   use Ada.Numerics;

   package Float_Functions is new Generic_Elementary_Functions (Float);

   Tolerance : constant Float := 1.0E-5;
   --  Float carries roughly seven significant digits; the exact-case kernel
   --  results are reached in a few operations, so they stay within this margin.

   Checks_Run    : Natural := 0;
   Checks_Failed : Natural := 0;

   Gen : Float_Random.Generator;
   --  Drives Gaussian_Random. Left unseeded so the generated sequence, and
   --  hence this test, is reproducible from run to run.

   function Deviate is new Normal_Distribution.Gaussian_Deviate (Float, Float_Functions);
   function Normal_Random is new Normal_Distribution.Gaussian_Random (Float, Gen, Float_Functions);

   procedure Check (Description : String;  Condition : Boolean);
   --  Records the outcome of a single check and prints one result line.

   function Sample_Standard_Deviation (Mu, Sigma : Float;  Samples : Positive) return Float;
   --  Draws Samples values from Normal_Random and returns their standard deviation.

   procedure Test_Deviate_Zero_Sigma;
   --  With Sigma = 0 the kernel returns Mu regardless of the uniform inputs.

   procedure Test_Deviate_Magnitude_Bound;
   --  The kernel deviate stays within the Box-Muller radius bound of 16.0.

   procedure Test_Normal_Random_Mean_And_Symmetry;
   --  Over many samples the mean approximates Mu and roughly half exceed Mu.

   procedure Test_Normal_Random_Standard_Deviation;
   --  The sample standard deviation approximates Sigma, and doubling Sigma
   --  roughly doubles it.

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

   -------------------------------
   -- Sample_Standard_Deviation --
   -------------------------------

   function Sample_Standard_Deviation (Mu, Sigma : Float;  Samples : Positive) return Float is
      Sum    : Float := 0.0;
      Sum_Sq : Float := 0.0;
      X      : Float;
      Mean   : Float;
   begin
      for Trial in 1 .. Samples loop
         X := Normal_Random (Mu, Sigma);
         Sum := Sum + X;
         Sum_Sq := Sum_Sq + X * X;
      end loop;
      Mean := Sum / Float (Samples);
      return Float_Functions.Sqrt (Sum_Sq / Float (Samples) - Mean * Mean);
   end Sample_Standard_Deviation;

   ------------------------------
   -- Test_Deviate_Zero_Sigma --
   ------------------------------

   procedure Test_Deviate_Zero_Sigma is
      Mu : constant Float := 5.0;
   begin
      Check ("Gaussian_Deviate with Sigma = 0 returns Mu",
             abs (Deviate (0.25, 0.50, Mu, 0.0) - Mu) <= Tolerance and then
             abs (Deviate (0.90, 0.10, Mu, 0.0) - Mu) <= Tolerance and then
             abs (Deviate (0.01, 0.99, Mu, 0.0) - Mu) <= Tolerance);
   end Test_Deviate_Zero_Sigma;

   -----------------------------------
   -- Test_Deviate_Magnitude_Bound --
   -----------------------------------

   procedure Test_Deviate_Magnitude_Bound is
      Max_Magnitude : constant Float := 16.0;
      --  Root is clamped to 16.0 and |Angle| <= 1.0, so |Deviate| <= 16.0 when
      --  Mu = 0.0 and Sigma = 1.0.
   begin
      Check ("Gaussian_Deviate magnitude is bounded for Mu = 0.0, Sigma = 1.0",
             abs Deviate (0.500, 0.500, 0.0, 1.0) <= Max_Magnitude and then
             abs Deviate (0.010, 0.990, 0.0, 1.0) <= Max_Magnitude and then
             abs Deviate (0.001, 0.250, 0.0, 1.0) <= Max_Magnitude);
   end Test_Deviate_Magnitude_Bound;

   ------------------------------------------
   -- Test_Normal_Random_Mean_And_Symmetry --
   ------------------------------------------

   procedure Test_Normal_Random_Mean_And_Symmetry is
      Samples  : constant := 200_000;
      Mu       : constant Float := 2.0;
      Sigma    : constant Float := 1.5;
      Mean_Tol : constant Float := 0.05;
      Sum      : Float := 0.0;
      Above    : Natural := 0;
      X        : Float;
   begin
      for Trial in 1 .. Samples loop
         X := Normal_Random (Mu, Sigma);
         Sum := Sum + X;
         if X > Mu then
            Above := Above + 1;
         end if;
      end loop;
      Check ("Gaussian_Random sample mean approximates Mu",
             abs (Sum / Float (Samples) - Mu) <= Mean_Tol);
      Check ("Gaussian_Random is roughly symmetric about Mu",
             abs (Float (Above) / Float (Samples) - 0.5) <= 0.02);
   end Test_Normal_Random_Mean_And_Symmetry;

   ------------------------------------------
   -- Test_Normal_Random_Standard_Deviation --
   ------------------------------------------

   procedure Test_Normal_Random_Standard_Deviation is
      Samples : constant := 200_000;
      Sd_1    : constant Float := Sample_Standard_Deviation (0.0, 1.0, Samples);
      Sd_2    : constant Float := Sample_Standard_Deviation (0.0, 2.0, Samples);
   begin
      Check ("Gaussian_Random sample standard deviation approximates Sigma = 1.0",
             abs (Sd_1 - 1.0) <= 0.05);
      Check ("Gaussian_Random spread grows in proportion to Sigma",
             abs (Sd_2 / Sd_1 - 2.0) <= 0.1);
   end Test_Normal_Random_Standard_Deviation;

begin
   Put_Line ("Running Normal_Distribution unit tests");
   Put_Line ("--------------------------------------");

   Test_Deviate_Zero_Sigma;
   Test_Deviate_Magnitude_Bound;
   Test_Normal_Random_Mean_And_Symmetry;
   Test_Normal_Random_Standard_Deviation;

   New_Line;
   Put_Line ("Checks run:    " & Checks_Run'Image);
   Put_Line ("Checks failed: " & Checks_Failed'Image);

   if Checks_Failed = 0 then
      Put_Line ("Result: ALL TESTS PASSED");
   else
      Put_Line ("Result: FAILURES DETECTED");
   end if;
end Normal_Distribution_Tests;
