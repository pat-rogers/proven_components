--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u math_utils_instances.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Math_Utilities; use Math_Utilities;

package Math_Utils_Instances
  with SPARK_Mode
is

   function Mapping is new Range_To_Domain_Mapping (Long_Long_Long_Integer);

   function Mapping is new Range_To_Domain_Mapping (Integer);

   function Float_Mapping is new Range_To_Domain_Mapping_Float (Float);

   function Bounded is new Bounded_Integer_Value (Integer);

   procedure Bound is new Bound_Integer_Value (Integer);

   function Limit is new Bounded_Floating_Value (Float);

   procedure Limit is new Bound_Floating_Value (Float);

end Math_Utils_Instances;
