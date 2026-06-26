--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u bounded_seq_instance.ads --no-inlining --level=2

pragma Assertion_Policy (Pre               => Check,
                         Pre'Class         => Check,
                         Dynamic_Predicate => Check);

with Bounded_Dynamic_Sequences;

package Bounded_Seq_Instance with SPARK_Mode is

   package Variable_Length_Strings is new Bounded_Dynamic_Sequences
     (Component     => Character,
      List_Index    => Positive,
      List          => String,
      "="           => "=");

   type Dynamic_String is new Variable_Length_Strings.Sequence;

end Bounded_Seq_Instance;
