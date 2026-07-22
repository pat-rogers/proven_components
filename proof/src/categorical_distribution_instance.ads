--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  Instantiation of the generic Categorical_Distribution, used to prove it.
--  GNATprove analyses instances, not generic bodies, so the proof is driven
--  through this concrete instantiation.

with Categorical_Distribution;

package Categorical_Distribution_Instance with SPARK_Mode is

   type Color is (Red, Green, Blue, Yellow);

   package Color_Distribution is new Categorical_Distribution (Color);

end Categorical_Distribution_Instance;
