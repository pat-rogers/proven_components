--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Random_Number_Generators with SPARK_Mode is

   ---------------------
   -- Scaled_To_Range --
   ---------------------

   function Scaled_To_Range
     (Value : Real;
      Lower : Real;
      Upper : Real)
      return Real
   is
      Clamped : constant Real := Real'Min (Real'Max (Value, 0.0), 1.0);
      Span    : constant Real := Upper - Lower;
      Raw     : constant Real := Lower + Span * Clamped;
   begin
      --  Clamp into Lower .. Upper: IEEE rounding may otherwise leave Raw a
      --  fraction outside the interval.
      return Real'Min (Real'Max (Raw, Lower), Upper);
   end Scaled_To_Range;

   ----------------------
   -- Gaussian_Deviate --
   ----------------------

   function Gaussian_Deviate
     (Uniform_1 : Real; -- a uniformly distributed random number
      Uniform_2 : Real; -- a uniformly distributed random number
      Mu        : Real;
      Sigma     : Real)
      return Real
   is
      use Real_Elementary_Functions;

      Min_Draw : constant Real := 1.0E-4;   -- keeps the Log argument positive
      Max_Log  : constant Real := 100.0;    -- bounds the magnitude of Log
      Max_Root : constant Real := 16.0;     -- bounds the Sqrt result

      U1 : constant Real := Real'Max (Uniform_1, Min_Draw);
      --  U1 >= Min_Draw > 0.0, satisfying the Log precondition

      U2 : constant Real := Real'Min (Real'Max (Uniform_2, 0.0), 1.0);
      --  U2 in 0.0 .. 1.0

      Log_U1 : constant Real := Real'Min (Real'Max (Log (U1, 10.0), -Max_Log), 0.0);
      --  Log_U1 in -Max_Log .. 0.0

      Radicand : constant Real := -2.0 * Log_U1;
      --  Radicand in 0.0 .. 2.0 * Max_Log, satisfying the Sqrt precondition

      Root : constant Real := Real'Min (Sqrt (Radicand), Max_Root);
      --  Root in 0.0 .. Max_Root

      Angle : constant Real := Cos (2.0 * Pi * U2);
      --  Angle in -1.0 .. 1.0 (postcondition of Cos)

      Deviate : constant Real := Root * Angle;
      --  Deviate in -Max_Root .. Max_Root
   begin
      return Mu + Sigma * Deviate;
   end Gaussian_Deviate;

   ---------------------------
   -- Scaled_Uniform_Random --
   ---------------------------

   function Scaled_Uniform_Random (Lower, Upper : Real) return Real is
      function Scaled is new Scaled_To_Range (Real);
   begin
      return Scaled (Real (Ada.Numerics.Float_Random.Random (RNG)), Lower, Upper);
   end Scaled_Uniform_Random;

   ---------------------
   -- Gaussian_Random --
   ---------------------

   function Gaussian_Random (Mu, Sigma : Real) return Real is
      function Deviate is new Gaussian_Deviate (Real, Real_Elementary_Functions);
   begin
      return Deviate
               (Real (Ada.Numerics.Float_Random.Random (RNG)),
                Real (Ada.Numerics.Float_Random.Random (RNG)),
                Mu,
                Sigma);
   end Gaussian_Random;

end Random_Number_Generators;
