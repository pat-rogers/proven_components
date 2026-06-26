--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Character_Queues;   use Character_Queues;
with Ada.Text_IO;        use Ada.Text_IO;

procedure Demo_Queues with SPARK_Mode is

   procedure Put (This : Queue) is
   begin
      Put ('"');
      for C of This loop
         Put (C);
      end loop;
      Put ('"');
   end Put;

   --------------------
   -- Demo_Deletions --
   --------------------

   procedure Demo_Deletions is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Queue (Capacity => Size);
      Value : Character;
   begin
      Put_Line ("Demo Deletions");
      Insert (Chars, 'a');
      Insert (Chars, 'b');
      Insert (Chars, 'c');
      Insert (Chars, 'd');
      Insert (Chars, 'e');
      Insert (Chars, 'f');
      pragma Assert (Model (Chars) = "abcdef");
      Remove (Chars, Value);
      pragma Assert (Value = 'a');
      pragma Assert (Model (Chars) = "bcdef");
      Delete (Chars, Number_To_Delete => 2);
      pragma Assert (Model (Chars) = "def");
      Delete (Chars, Number_To_Delete => 1);
      pragma Assert (Model (Chars) = "ef");
      Delete (Chars, Number_To_Delete => 2);
      pragma Assert (Model (Chars) = "");
   end Demo_Deletions;

   ---------------
   -- Demo_Copy --
   ---------------

   procedure Demo_Copy is
      Size   : constant := 10; -- arbitrary but must match Inputs'Length
      Inputs : constant String (1 .. Size) := "abcdefghij";
      Chars  : Queue (Capacity => Size);
   begin
      Put_Line ("Demo Copy");
      pragma Assert (Empty (Chars));
      for C of Inputs loop
         Insert (Chars, C);
      end loop;
      pragma Assert (Model (Chars) = "abcdefghij");
      pragma Assert (not Empty (Chars));
      pragma Assert (Full (Chars));
      pragma Assert (Extent (Chars) = Size);
      declare
         Temp : Queue (Capacity => Size);
      begin
         Copy (Chars, Target => Temp);
         pragma Assert (Chars = Temp);
         pragma Assert (Model (Temp) = "abcdefghij");
         pragma Assert (Full (Temp));
         pragma Assert (Extent (Temp) = Size);
      end;
   end Demo_Copy;

   -------------------
   -- Demo_Put_Loop --
   -------------------

   procedure Demo_Put_Loop is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Queue (Capacity => Size);
   begin
      Put_Line ("Demo Insert in a loop");
      pragma Assert (Empty (Chars));
      for C in Character range 'a' .. 'j' loop
         Insert (Chars, C);
      end loop;
      pragma Assert (Full (Chars));
      --  the first 10 characters are "abcdefghij"; Capacity is
      --  arbitrarily set to 10.
      pragma Assert (Model (Chars) = "abcdefghij");
   end Demo_Put_Loop;

   -----------------
   -- Demo_Remove --
   -----------------

   procedure Demo_Remove is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Queue (Capacity => Size);
      Value : Character;
   begin
      Put_Line ("Demo Remove");
      pragma Assert (Empty (Chars));
      Insert (Chars, 'a');
      Insert (Chars, 'b');
      Insert (Chars, 'c');
      Remove (Chars, Value);
      pragma Assert (Value = 'a');
      Remove (Chars, Value);
      pragma Assert (Value = 'b');
      Remove (Chars, Value);
      pragma Assert (Value = 'c');
      pragma Assert (Empty (Chars));
   end Demo_Remove;

   ---------------------
   -- Demo_Iterations --
   ---------------------

   procedure Demo_Iterations is
      Size  : constant Positive_Element_Count := 10;
      Chars : Queue (Capacity => Size);
      Dummy : Character;
   begin
      Put_Line ("Demo iterations. Capacity is" & Size'Image);

      Put ("   Initially empty   : "); Put (Chars); New_Line; -- output should be ""

      Put ("   Inserted 10 chars : ");
      for C in Character range 'a' .. 'j' loop
         Insert_Preserving (Chars, C);  -- not intending to overwrite
      end loop;
      Put (Chars); New_Line;

      Put ("   Removed 5 chars   : ");
      for K in 1 .. 5 loop
         Remove (Chars, Dummy);
      end loop;
      Put (Chars); New_Line;

      Put ("   Inserted 6 chars  : ");
      for C in Character range 'u' .. 'z' loop
         Insert (Chars, C);
      end loop;
      Put (Chars); New_Line;
   end Demo_Iterations;

begin
   Demo_Iterations;
   Demo_Copy;
   Demo_Deletions;
   Demo_Remove;
   Demo_Put_Loop;

   Put_Line ("Demo complete");
end Demo_Queues;
