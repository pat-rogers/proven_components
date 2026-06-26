--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides generic functions for uniformly- and
--  normaly-distributed random numbers.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;
use Ada.Numerics;

package Random_Number_Generators with
  SPARK_Mode,
  Always_Terminates
is

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

   generic
      type Real is digits <>;
      with package Real_Elementary_Functions is new Generic_Elementary_Functions (Real);
   function Gaussian_Deviate
     (Uniform_1 : Real; -- a uniformly distributed random number
      Uniform_2 : Real; -- a uniformly distributed random number
      Mu        : Real;
      Sigma     : Real)
      return Real
   with
     Pre  => abs Mu <= Real'Last / 4.0 and then abs Sigma <= Real'Last / 64.0,
     Post => abs Gaussian_Deviate'Result <= Real'Last / 2.0;
   --  Box-Muller transform of two uniform values into a normally distributed
   --  value with mean Mu and standard deviation Sigma.

   --------------------  Random Generator-driven wrappers -------------------------
   --
   --  These draw their samples from a Float_Random generator, whose use is
   --  not valid in SPARK. They are therefore excluded from analysis and only
   --  delegate to the proven routines above.

   generic
      type Real is digits <>;
      RNG : in out Float_Random.Generator;
   function Scaled_Uniform_Random (Lower, Upper : Real) return Real with
     SPARK_Mode => Off,
     Pre  => Lower > 0.0 and then Lower < Upper and then Upper <= Real'Last / 2.0,
     Post => Scaled_Uniform_Random'Result in Lower .. Upper;
   --  Returns a uniformly distributed value within the range Lower .. Upper

   generic
      type Real is digits <>;
      RNG : in out Float_Random.Generator;
      with package Real_Elementary_Functions is new Generic_Elementary_Functions (Real);
   function Gaussian_Random (Mu, Sigma : Real) return Real with
     SPARK_Mode => Off,
     Pre  => abs Mu <= Real'Last / 4.0 and then abs Sigma <= Real'Last / 64.0,
     Post => abs Gaussian_Random'Result <= Real'Last / 2.0;
   --  Returns a normally distributed value with mean Mu and standard deviation Sigma

end Random_Number_Generators;
