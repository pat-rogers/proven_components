--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u character_search.ads --no-inlining --level=2

pragma SPARK_Mode;

pragma Assertion_Policy (Pre               => Ignore,
                         Pre'Class         => Ignore,
                         Dynamic_Predicate => Check);

with Search_Routines;

package Character_Search is new Search_Routines
  (Item  => Character,
   Index => Positive,
   List  => String);
