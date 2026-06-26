--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u fx_images_instance.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Fixed_Point_Images;

package FX_Images_Instance with SPARK_Mode is

   type Fixed_Value is delta 0.01 range -1000.0 .. 1000.0;

   package Instance is new Fixed_Point_Images (Fixed_Value);

end FX_Images_Instance;
