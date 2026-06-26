--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Fixed_Point_Images with
  SPARK_Mode
is

   function Unsigned_Image (S : String) return String with
     Post => Unsigned_Image'Result'First = 1 and then
             Unsigned_Image'Result'Length <= S'Length;
   --  Returns S without its first character (a sign or blank), renumbered from
   --  index 1. Returns "" when S is too short to carry a sign and a digit.

   function Renumbered (S : String) return String with
     Post => Renumbered'Result'First = 1 and then
             Renumbered'Result'Length = S'Length;
   --  Returns the characters of S renumbered to start at index 1.

   function Signed_Image (S : String) return String with
     Post => Signed_Image'Result'First = 1 and then
             Signed_Image'Result'Length in 1 .. Natural'Max (S'Length, 1) and then
             Signed_Image'Result (1) = '-';
   --  Returns S with its first character replaced by an explicit '-', so the
   --  leading minus sign is structurally present. Returns "-" for a short S.

   function Index_Of (Source : String; What : Character) return Natural with
     Post => (if Index_Of'Result /= 0
              then Index_Of'Result in Source'Range and then
                   Source (Index_Of'Result) = What);
   --  Returns the index of the first occurrence of What in Source, or 0 if absent

   procedure Image_Length_Bounded (Input : Fixed) with
     Ghost,
     Import,
     Global => null,
     Post => Fixed'Image (Input)'Length <= Fixed'Width;
   --  Axiom: Fixed'Width is, by definition (RM 3.5), the maximum length of
   --  Fixed'Image over all values of the type. GNATprove has no model of this
   --  relationship, so this unverifiable lemma asserts it for the prover.

   --------------------
   -- Unsigned_Image --
   --------------------

   function Unsigned_Image (S : String) return String is
   begin
      if S'Length <= 1 then
         return "";
      end if;
      declare
         Result : String (1 .. S'Length - 1);
      begin
         Result := S (S'First + 1 .. S'Last);  -- sliding assignment
         return Result;
      end;
   end Unsigned_Image;

   ----------------
   -- Renumbered --
   ----------------

   function Renumbered (S : String) return String is
      Result : String (1 .. S'Length);
   begin
      Result := S;  -- sliding assignment
      return Result;
   end Renumbered;

   ------------------
   -- Signed_Image --
   ------------------

   function Signed_Image (S : String) return String is
   begin
      if S'Length <= 1 then
         return "-";
      end if;
      declare
         Result : String (1 .. S'Length) := (others => '-');
      begin
         --  Position 1 keeps '-'; positions 2 .. Last take S's digits.
         Result (2 .. Result'Last) := S (S'First + 1 .. S'Last);
         return Result;
      end;
   end Signed_Image;

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

   -----------
   -- Image --
   -----------

   function Image (Input : Fixed; Leading_Blank : Boolean := False) return String is
      Img : constant String := Fixed'Image (Input);
   begin
      Image_Length_Bounded (Input);  -- Img'Length <= Fixed'Width
      --  Fixed'Image yields standard decimal notation: "-ddd.ddd" (negative)
      --  or " ddd.ddd" (non-negative, with a leading blank). Reformat per the
      --  sign and the Leading_Blank request, building sized buffers rather
      --  than catenating (which has no provable upper length bound).
      if Input < 0.0 then
         return Signed_Image (Img);
      elsif Leading_Blank then
         return Renumbered (Img);
      else
         return Unsigned_Image (Img);
      end if;
   end Image;

   ----------------------
   -- Fractional_Image --
   ----------------------

   function Fractional_Image (Input : Fixed; Length : Natural) return String is
      S      : constant String  := Fixed'Image (Input);
      Dot    : constant Natural := Index_Of (S, '.');
      Result : String (1 .. Length) := (others => '0');
   begin
      --  For Input in [0.0, 1.0), Fixed'Image yields " 0.ddd". Copy the
      --  fraction digits after the point into Result, padding with '0' when
      --  the type has fewer digits and truncating when it has more. A missing
      --  '.', which Fixed'Image never produces, leaves Result all zeros.
      if Dot /= 0 and then Dot < S'Last then
         declare
            Available : constant Natural := S'Last - Dot;
            Kept      : constant Natural := Natural'Min (Length, Available);
         begin
            Result (1 .. Kept) := S (Dot + 1 .. Dot + Kept);
         end;
      end if;
      return Result;
   end Fractional_Image;

end Fixed_Point_Images;
