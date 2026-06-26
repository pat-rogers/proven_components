--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides image utilities for fixed-point types. The
--  images returned are in standard notation, rather than scientific or
--  engineering notation.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic
   type Fixed is delta <>;
package Fixed_Point_Images with
  SPARK_Mode,
  Always_Terminates
is

   function Image
     (Input         : Fixed;
      Leading_Blank : Boolean := False)
   return String with
     Post => Image'Result'First = 1 and then
             (if Input < 0.0 then Image'Result (1) = '-') and then
             Image'Result'Length <= Fixed'Width;
   --  Returns the image of Input in standard (i.e., not scientific) notation.
   --  The number of fractional digits is intrinsic to the fixed-point type.
   --  Image only reformats Fixed'Image, so its length never exceeds the
   --  maximum image length of the type, Fixed'Width.

   function Fractional_Image
     (Input  : Fixed;
      Length : Natural)
   return String with
     Pre  => Input >= 0.0 and then
             Input < 1.0,
     Post => Fractional_Image'Result'First = 1 and then
             Fractional_Image'Result'Length = Length;
   --  Returns a string of exactly Length decimal digits for the fractional
   --  value Input. Digits beyond the type's intrinsic precision are '0'.

end Fixed_Point_Images;
