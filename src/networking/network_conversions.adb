--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with System; use System;

package body Network_Conversions with SPARK_Mode is

   Host_Is_Little_Endian : constant Boolean := System.Default_Bit_Order = System.Low_Order_First;

   ----------------
   -- To_Network --
   ----------------

   function To_Network (Value : in Unsigned_32) return Unsigned_32 is
     (if Host_Is_Little_Endian then
         Shift_Left  (Value and 16#0000_00FF#, 24) or
         Shift_Left  (Value and 16#0000_FF00#, 8)  or
         Shift_Right (Value and 16#00FF_0000#, 8)  or
         Shift_Right (Value, 24)
      else Value);

   ----------------
   -- To_Network --
   ----------------

   function To_Network (Value : Unsigned_16) return Unsigned_16 is
     (if Host_Is_Little_Endian then
         Rotate_Left (Value, 8)
      else Value);

   -------------
   -- To_Host --
   -------------

   function To_Host (Value : Unsigned_32) return Unsigned_32 is
     (if Host_Is_Little_Endian then
         Shift_Left  (Value and 16#0000_00FF#, 24) or
         Shift_Left  (Value and 16#0000_FF00#, 8)  or
         Shift_Right (Value and 16#00FF_0000#, 8)  or
         Shift_Right (Value, 24)
      else Value);

   -------------
   -- To_Host --
   -------------

   function To_Host (Value : Unsigned_16) return Unsigned_16 is
     (if Host_Is_Little_Endian then
         Rotate_Left (Value, 8)
      else Value);

end Network_Conversions;
