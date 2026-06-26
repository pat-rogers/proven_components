--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u random_number_generator_instances.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Ada.Numerics.Generic_Elementary_Functions;
with Random_Number_Generators; use Random_Number_Generators;

package Random_Number_Generator_Instances
  with SPARK_Mode
is

   function Scaled is new Scaled_To_Range (Float);

   function Scaled is new Scaled_To_Range (Long_Float);

   package Float_Functions is
     new Ada.Numerics.Generic_Elementary_Functions (Float);

   package Long_Float_Functions is
     new Ada.Numerics.Generic_Elementary_Functions (Long_Float);

   function Deviate is new Gaussian_Deviate (Float, Float_Functions);

   function Deviate is new Gaussian_Deviate (Long_Float, Long_Float_Functions);

end Random_Number_Generator_Instances;
