--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u noise_filters_instances.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Recursive_Moving_Average_Filters;
with Simple_Moving_Average_Filters;

package Noise_Filters_Instances
  with SPARK_Mode
is

   package RMA_Integers is new Recursive_Moving_Average_Filters
     (Long_Integer, Long_Integer);

   function As_Float (Input : Integer) return Float is
     (Float (Input));

   package SMA_Integers is new Simple_Moving_Average_Filters
     (Sample => Integer, Output => Float, As_Output => As_Float);

end Noise_Filters_Instances;
