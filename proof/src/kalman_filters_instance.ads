--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u kalman_filters_instance.ads --no-inlining --level=2

pragma Warnings (Off, "no Global");
--  for Ada.Numerics.Generic_Real_Arrays

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Kalman_Filters_Linear;
with Ada.Numerics.Generic_Real_Arrays;

package Kalman_Filters_Instance with SPARK_Mode is

   package Float_Real_Arrays is new Ada.Numerics.Generic_Real_Arrays (Float);

   package Float_Kalman_Filters is new Kalman_Filters_Linear
     (Real   => Float,
      VM_Ops => Float_Real_Arrays);

end Kalman_Filters_Instance;
