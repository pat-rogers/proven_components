--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof.gpr -j0 --output=oneline -u character_sets.ads --no-inlining --level=2

pragma SPARK_Mode;

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Sequential_Discrete_Sets;

package Character_Sets is new Sequential_Discrete_Sets
  (Element           => Character,
   Set_Member_Extent => Integer);
