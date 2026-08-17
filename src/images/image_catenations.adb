--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Ada.Strings.Fixed;
with Ada.Strings.Maps;  use Ada.Strings.Maps;

package body Image_Catenations is

   Blanks : constant Character_Set := To_Set (" " & ASCII.HT & ASCII.LF & ASCII.CR & ASCII.VT & ASCII.FF);
   --  The characters that function Trimmed removes from the ends. Note that the
   --  Image attribute applied to a composite type produces a multi-line result,
   --  beginning with a line terminator, so we're removing those as well.

   function Trimmed (Source : String) return String;
   --  Returns Source without the leading and/or trailing Blanks, as indicated
   --  by the generic formal object Trim_Option.

   ---------
   -- "&" --
   ---------

   function "&" (Left : String;  Right : Formal) return String is
     (Left & (if Trimming then Trimmed (Right'Image) else Right'Image));

   ---------
   -- "&" --
   ---------

   function "&" (Left : Formal;  Right : String) return String is
     ((if Trimming then Trimmed (Left'Image) else Left'Image) & Right);

   -------------
   -- Trimmed --
   -------------

   function Trimmed (Source : String) return String is
   begin
      case Trim_Option is
         when Ada.Strings.Left  => return Ada.Strings.Fixed.Trim (Source, Left => Blanks,   Right => Null_Set);
         when Ada.Strings.Right => return Ada.Strings.Fixed.Trim (Source, Left => Null_Set, Right => Blanks);
         when Ada.Strings.Both  => return Ada.Strings.Fixed.Trim (Source, Left => Blanks,   Right => Blanks);
      end case;
   end Trimmed;

end Image_Catenations;
