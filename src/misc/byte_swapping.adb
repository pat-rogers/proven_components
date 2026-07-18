--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Interfaces;
with System.Address_To_Access_Conversions;

package body Byte_Swapping with SPARK_Mode => Off is

   type Word16 is new Interfaces.Unsigned_16;

   type Word32 is new Interfaces.Unsigned_32;

   package Word16_Ops is new System.Address_To_Access_Conversions (Word16);
   package Word32_Ops is new System.Address_To_Access_Conversions (Word32);

   use Word16_Ops, Word32_Ops;

   ------------
   -- Swap16 --
   ------------

   procedure Swap16 (Location : System.Address) is
      X : Word16 renames To_Pointer (Location).all;
   begin
      X := Shift_Left (X, 8) or Shift_Right (X, 8);
   end Swap16;

   ------------
   -- Swap32 --
   ------------

   procedure Swap32 (Location : System.Address) is
      X : Word32 renames To_Pointer (Location).all;
   begin
      X := (Shift_Right (X, 24) and 16#0000_00FF#) or
           (Shift_Right (X, 8)  and 16#0000_FF00#) or
           (Shift_Left  (X, 8)  and 16#00FF_0000#) or
            Shift_Left  (X, 24);
   end Swap32;

end Byte_Swapping;
