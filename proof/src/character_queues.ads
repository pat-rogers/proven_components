--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u character_queues.ads --no-inlining --level=2

pragma SPARK_Mode;

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Sequential_Bounded_Queues;

package Character_Queues is new Sequential_Bounded_Queues
  (Element      => Character,
   Base_Integer => Short_Integer);
