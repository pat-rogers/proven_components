--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides generic functions for normally-distributed random
--  numbers.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;
use Ada.Numerics;

package Normal_Distribution with
  SPARK_Mode,
  Always_Terminates
is

   --  Gaussian_Random is the intended client entry point: instantiate it with
   --  your floating-point type, a Float_Random generator, and the matching
   --  elementary-functions package, then call it to obtain normally-distributed
   --  random values. It draws its samples from the Float_Random generator, whose
   --  use is not valid in SPARK, so it is excluded from analysis and only
   --  delegates to the proven Gaussian_Deviate kernel below.

   generic
      type Real is digits <>;
      RNG : in out Float_Random.Generator;
      with package Real_Elementary_Functions is new Generic_Elementary_Functions (Real);
   function Gaussian_Random (Mu, Sigma : Real) return Real with
     SPARK_Mode => Off,
     Pre  => abs Mu <= Real'Last / 4.0 and then abs Sigma <= Real'Last / 64.0,
     Post => abs Gaussian_Random'Result <= Real'Last / 2.0;
   --  Returns a normally distributed value with mean Mu and standard deviation Sigma

   --  Gaussian_Deviate is the underlying proven kernel. Clients that already
   --  hold their own pair of uniform values (rather than a Float_Random
   --  generator) may instantiate and call it directly; otherwise it exists to
   --  support Gaussian_Random and need not be instantiated separately.

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

end Normal_Distribution;
