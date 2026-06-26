--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u control_instances.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with PID_Control;
with PI_Control;

package Control_Instances with
  SPARK_Mode
is

  package PID is new PID_Control (Float, Long_Float);

  package PI is new PI_Control (Float, Long_Float);

 end Control_Instances;
