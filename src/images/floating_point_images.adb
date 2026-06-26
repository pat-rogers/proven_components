--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Floating_Point_Images with
  SPARK_Mode
is

   Max_Integral_Digits : constant Positive := Real'Machine_Emax;
   --  An upper bound on the digit count of the integral part of any Real
   --  value: a magnitude below 2.0**Machine_Emax has fewer than Machine_Emax
   --  decimal digits. Used to bound the integral image length.

   function Internal_Image
     (Whole_Part : String;
      Fraction   : Real;
      Aft        : Natural := 0)
   return String with
     Pre  => Fraction >= 0.0 and then
             Fraction < 1.0 and then
             Whole_Part'First = 1 and then
             Whole_Part'Length < Positive'Last - 2,
     Post => Internal_Image'Result'First = 1 and then
             Internal_Image'Result'Length <= Whole_Part'Length + Real'Digits + 2;
   --  Formats the decimal expansion given a pre-split whole-part string and
   --  fractional value.

   function Fractional_Part (Input : Real) return Real with
     Post => Fractional_Part'Result >= 0.0 and then
             Fractional_Part'Result < 1.0;
   --  Returns the non-negative fractional magnitude of Input.

   function Integral_Image (Input : Real) return String with
     Post => Integral_Image'Result'First = 1 and then
             Integral_Image'Result'Length in 1 .. Max_Integral_Digits;
   --  Returns the image of the 'whole part' of Input, without the negative sign (if any)

   function Index_Of (Source : String; What : Character) return Natural with
     Post => (if Index_Of'Result /= 0 then
                Index_Of'Result in Source'Range and then
                Source (Index_Of'Result) = What);
   --  Returns the index of the first occurrence of What in Source, or 0 if absent

   function Parsed_Exponent (Source : String) return Integer with
     Post => Parsed_Exponent'Result in -Max_Integral_Digits .. Max_Integral_Digits;
   --  Parses an optional leading sign followed by decimal digits, saturating
   --  the magnitude at Max_Integral_Digits. A non-digit character ends the
   --  scan.

   ---------------------
   -- Fractional_Part --
   ---------------------

   function Fractional_Part (Input : Real) return Real is
     (abs (Input - Real'Truncation (Input)));

   ----------------------
   -- Fractional_Image --
   ----------------------

   function Fractional_Image (Input : Real; Length : Natural) return String is
      Number : constant Real      := Input * 10.0;
      K      : constant Integer   := Integer (Real'Truncation (Number));
      Digit  : constant Character := Character'Val (K + Character'Pos ('0'));
   begin
      if Length = 0 then
         return "";
      else
         return (1 => Digit) & Fractional_Image (Fractional_Part (Number), Length - 1);
      end if;
   end Fractional_Image;

   -----------
   -- Image --
   -----------

   function Internal_Image
     (Whole_Part : String;
      Fraction   : Real;
      Aft        : Natural := 0)
   return String
   is
      Max_Digits_Possible : constant Natural := (if Whole_Part'Length >= Real'Digits + 1 then 0
                                                 else Real'Digits + 1 - Whole_Part'Length);
      Significant_Digits  : constant Natural := (if Aft = 0 then Max_Digits_Possible
                                                 else Natural'Min (Max_Digits_Possible, Aft));
   begin
      if Significant_Digits > 0 then
         return Whole_Part &
                '.' &
                Fractional_Image (Fraction, Significant_Digits);
      else
         return Whole_Part & ".0";
      end if;
   end Internal_Image;

   -----------
   -- Image --
   -----------

   function Image
     (Input         : Real;
      Aft           : Natural := 0;
      Leading_Blank : Boolean := False)
   return String
   is
      Suffix : constant String :=
                  Internal_Image
                    (Whole_Part => Integral_Image (Input),
                     Fraction   => Fractional_Part (Input),
                     Aft        => Aft);
   begin
      if Input < 0.0 then
         return '-' & Suffix;
      else
         declare
            Prefix : constant String := (if Leading_Blank then " " else "");
         begin
            return Prefix & Suffix;
         end;
      end if;
   end Image;

   --------------
   -- Index_Of --
   --------------

   function Index_Of (Source : String; What : Character) return Natural is
   begin
      for I in Source'Range loop
         if Source (I) = What then
            return I;
         end if;
      end loop;
      return 0;
   end Index_Of;

   ---------------------
   -- Parsed_Exponent --
   ---------------------

   function Parsed_Exponent (Source : String) return Integer is
      Acc      : Natural range 0 .. Max_Integral_Digits := 0;
      Negative : Boolean := False;
      Started  : Boolean := False;  -- True once the optional sign is consumed
   begin
      for I in Source'Range loop
         declare
            C : constant Character := Source (I);
         begin
            if C in '0' .. '9' then
               declare
                  Digit : constant Natural := Character'Pos (C) - Character'Pos ('0');
               begin
                  if Acc <= (Max_Integral_Digits - Digit) / 10 then
                     Acc := Acc * 10 + Digit;
                  else
                     Acc := Max_Integral_Digits;  -- saturate
                  end if;
               end;
               Started := True;
            elsif (C = '-' or else C = '+') and then not Started then
               Negative := C = '-';
               Started := True;
            else
               exit;  -- unexpected character ends the scan
            end if;
         end;
      end loop;
      return (if Negative then -Acc else Acc);
   end Parsed_Exponent;

   --------------------
   -- Integral_Image --
   --------------------

   function Integral_Image (Input : Real) return String is
      S   : constant String  := Real'Image (abs (Input));
      Dot : constant Natural := Index_Of (S, '.');
      E   : constant Natural := Index_Of (S, 'E');
   begin
      --  Real'Image yields standard scientific notation " d.ddddE+-NN".
      --  Reformat it: the integral part is the mantissa digits with the
      --  decimal point shifted right NN places, zero-filled past the
      --  available digits. The "0" returns are a defensive default for
      --  structurally unexpected input, which Real'Image never produces.
      if Dot = 0 or else E = 0 or else
         S'First /= 1 or else S'Last < 4 or else
         Dot not in 3 .. E - 1 or else E >= S'Last
      then
         return "0";
      end if;

      declare
         Exp : constant Integer := Parsed_Exponent (S (E + 1 .. S'Last));
      begin
         if Exp < 0 then
            return "0";  -- magnitude below 1.0 has no integral digits
         end if;

         declare
            Mantissa  : constant String   := S (2) & S (Dot + 1 .. E - 1);
            Int_Count : constant Positive := Natural'Min (Exp + 1, Max_Integral_Digits);
            Kept      : constant Natural  := Natural'Min (Int_Count, Mantissa'Length);
            Result    : String (1 .. Int_Count) := (others => '0');
         begin
            --  Leading Kept positions take real digits; the rest stay '0'.
            Result (1 .. Kept) := Mantissa (Mantissa'First .. Mantissa'First + (Kept - 1));
            return Result;
         end;
      end;
   end Integral_Image;

end Floating_Point_Images;
