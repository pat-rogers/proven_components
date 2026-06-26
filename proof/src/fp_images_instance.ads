--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u fp_images_instance.ads --no-inlining --level=2

pragma SPARK_Mode;

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Floating_Point_Images;
package FP_Images_Instance is new Floating_Point_Images (Float);
