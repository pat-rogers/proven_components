--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides generic functions for uniformly-distributed random
--  numbers.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Ada.Numerics.Float_Random;
use Ada.Numerics;

package Uniform_Distribution with
  SPARK_Mode,
  Always_Terminates
is

   --  Scaled_Uniform_Random is the intended client entry point: instantiate it
   --  with your floating-point type and a Float_Random generator, then call it
   --  to obtain uniformly-distributed random values. It draws its sample from
   --  the Float_Random generator, whose use is not valid in SPARK, so it is
   --  excluded from analysis and only delegates to the proven Scaled_To_Range
   --  kernel below.

   generic
      type Real is digits <>;
      RNG : in out Float_Random.Generator;
   function Scaled_Uniform_Random (Lower, Upper : Real) return Real with
     SPARK_Mode => Off,
     Pre  => Lower > 0.0 and then Lower < Upper and then Upper <= Real'Last / 2.0,
     Post => Scaled_Uniform_Random'Result in Lower .. Upper;
   --  Returns a uniformly distributed value within the range Lower .. Upper

   --  Scaled_To_Range is the underlying proven kernel. Clients that already
   --  hold their own source of uniform values (rather than a Float_Random
   --  generator) may instantiate and call it directly; otherwise it exists to
   --  support Scaled_Uniform_Random and need not be instantiated separately.

   generic
      type Real is digits <>;
   function Scaled_To_Range
     (Value : Real;
      Lower : Real;
      Upper : Real)
      return Real
   with
     Pre  => Lower > 0.0   and then
             Lower < Upper and then
             Upper <= Real'Last / 2.0,
     Post => Scaled_To_Range'Result in Lower .. Upper;
   --  Maps a uniform Value (clamped to 0.0 .. 1.0) onto the range
   --  Lower .. Upper.

end Uniform_Distribution;
