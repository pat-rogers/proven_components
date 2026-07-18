--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides in-place byte reversal of the 16-bit and 32-bit
--  values at a given address.
--
--  The reversal is unconditional: these routines do not consult the host's
--  endianness, so deciding whether a swap is needed at all remains with the
--  caller. Each routine is its own inverse, so one operation serves both
--  directions of conversion.
--
--  The operand is designated by its address rather than passed by value, so
--  that one routine serves any type of the corresponding size. The price is
--  the alignment obligation stated on each declaration below, which the
--  caller must meet.
--
--  SPARK_Mode is disabled because there's no way to use the package effectively
--  in SPARK code. Leaving it in Auto mode would just mislead the user, and
--  enabling SPARK_Mode causes a bunch of warnings from the Examiner, and
--  complaints that the Swap routines have no effect. Disabling SPARK_Mode is
--  the cleanest approach for all concerned. As a result, this package is not
--  formally proven to any level. It works, we just can't prove it other than by
--  inspection. Fortunately the code is extremely simple and idiomatically well
--  known.

with System;
with System.Storage_Elements;  use type System.Storage_Elements.Storage_Offset;

package Byte_Swapping with SPARK_Mode => Off is

   pragma Assertion_Policy (Pre => Ignore);
   --  The preconditions below state caller obligations that these routines
   --  cannot check meaningfully anyway: an address that is misaligned, or that
   --  does not designate an object of the swapped size, is erroneous either
   --  way. They are stated for the reader, not for execution: these routines
   --  are inlined into hot paths, where a per-call test-and-branch would cost
   --  more than the swap itself. The policy is set here, at the point of
   --  declaration, so that it governs regardless of the assertion policy a
   --  client compiles under.

   procedure Swap16 (Location : System.Address) with
     Pre => Location mod 2 = 0,
     Inline;
   --  Reverse, in place, the two bytes of the 16-bit value at Location.
   --  Location must be even because the value is accessed as a whole
   --  16-bit object; a misaligned access is erroneous, and on some targets
   --  raises a hardware fault.

   procedure Swap32 (Location : System.Address) with
     Pre => Location mod 4 = 0,
     Inline;
   --  Reverse, in place, the four bytes of the 32-bit value at Location.
   --  Location must be a multiple of four because the value is accessed as
   --  a whole 32-bit object; a misaligned access is erroneous, and on some
   --  targets raises a hardware fault.

end Byte_Swapping;
