--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Uniform_Distribution with SPARK_Mode is

   ---------------------------
   -- Scaled_Uniform_Random --
   ---------------------------

   function Scaled_Uniform_Random (Lower, Upper : Real) return Real is
      function Scaled is new Scaled_To_Range (Real);
   begin
      return Scaled (Real (Ada.Numerics.Float_Random.Random (RNG)), Lower, Upper);
   end Scaled_Uniform_Random;

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

end Uniform_Distribution;
