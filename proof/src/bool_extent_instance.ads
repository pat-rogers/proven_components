--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u bool_extent_instance.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Boolean_Array_Extent;

package Bool_Extent_Instance with SPARK_Mode is

   type List is array (Character) of Boolean;

   package List_Properties is new Boolean_Array_Extent
     (Element => Character,
      List    => List,
      Counter => Integer);

end Bool_Extent_Instance;
