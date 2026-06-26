--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides image utilities for floating point types.
--  The images returned are in standard notation, rather than scientific
--  or engineering notation.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic
   type Real is digits <>;
package Floating_Point_Images with
  SPARK_Mode,
  Always_Terminates
is

   function Image
     (Input         : Real;
      Aft           : Natural := 0;
      Leading_Blank : Boolean := False)
   return String with
     Post => Image'Result'First = 1 and then
             (if Input < 0.0 then Image'Result (1) = '-') and then
             Image'Result'Length <= Real'Machine_Emax + Real'Digits + 3;
   --  Returns the image of Input in standard (i.e., not scientific) notation.
   --  The result length is bounded by the integral digits (at most
   --  Real'Machine_Emax), the fractional digits (at most Real'Digits), the
   --  decimal point, the sign, and a possible leading blank.
   --  Aft is the number of digits to display after the decimal point. If
   --  zero, the number of available significant digits will be used, otherwise
   --  the value passed to Aft will be used, up to the max number of digits
   --  possible.

   function Fractional_Image
     (Input  : Real;
      Length : Natural)
   return String with
      Pre  => Input >= 0.0 and then Input < 1.0,
      Post => Fractional_Image'Result'Length = Length,
      Subprogram_Variant => (Decreases => Length);
   --  Returns a string of exactly Length decimal digits for the fractional
   --  value Input.  The interval [0.0, 1.0) is required because each step
   --  multiplies by 10 and truncates; Input < 1.0 guarantees the truncated
   --  value is a single digit in 0..9.

end Floating_Point_Images;
