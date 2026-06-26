--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof.gpr -j0 --output=oneline -u character_sorting.ads --no-inlining --level=2

pragma SPARK_Mode;

pragma Assertion_Policy (Pre               => Ignore,
                         Pre'Class         => Ignore,
                         Dynamic_Predicate => Check);
--  Note that the above explicit Ignore values are the same semantically as
--  saying nothing, because Ignoring them is the default. But in this case being
--  explicit is helpful because the preconditions (indirectly) call ghost code,
--  and the ghost code is almost certainly set to Ignore. If preconditions were
--  set to be checked the builder would rightly complain that the two policies
--  conflict.

with Sort_Routines;

package Character_Sorting is new Sort_Routines
  (Element => Character,
   Index   => Positive,
   List    => String);
