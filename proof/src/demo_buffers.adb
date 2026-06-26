--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Character_Buffers;  use Character_Buffers;
with Ada.Text_IO;        use Ada.Text_IO;

procedure Demo_Buffers with SPARK_Mode is

   ---------
   -- Put --
   ---------

   procedure Put (This : Ring_Buffer) is
   begin
      Put ('"');
      for C of This loop
         Put (C);
      end loop;
      Put ('"');
   end Put;

   -----------------------
   -- Demo_Remove_Array --
   -----------------------

   procedure Demo_Remove_Array is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Ring_Buffer (Capacity => Size);
      Items : Elements (10 .. 20) with Relaxed_Initialization;
      Last  : Element_Count;
   begin
      Put_Line ("Demo Removing an array of elements");
      pragma Assert (Empty (Chars));
      Insert_Preserving (Chars, "abcd");
      pragma Assert (Model (Chars) = "abcd");
      pragma Assert (Extent (Chars) = 4);
      --  Put_Line ("Chars prior to removal: ");
      --  Put (Chars);
      --  New_Line;
      Remove (Chars, Items, Last);
      pragma Assert (Empty (Chars));
      pragma Assert (Model (Chars) = "");
      pragma Assert (Last = Items'First + 4 - 1);
      pragma Assert (Items (Items'First .. Last) = "abcd");
      --  Put_Line ("Chars after removal: ");
      --  Put (Chars);
      --  New_Line;
      --  Put ("Items: """);
      --  for K in Items'First .. Last loop
      --     Put (Items (K));
      --  end loop;
      --  Put_Line ("""");
   end Demo_Remove_Array;

   ----------------------------------
   -- Demo_Insert_Preserving_Array --
   ----------------------------------

   procedure Demo_Insert_Preserving_Array is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Ring_Buffer (Capacity => Size);
   begin
      Put_Line ("Demo Insert_Preserving for inserting an array");
      pragma Assert (Empty (Chars));

      Insert_Preserving (Chars, "abcd");
      --  Put (Chars); New_Line;
      pragma Assert (Extent (Chars) = 4);
      pragma Assert (Model (Chars) = "abcd");

      Insert_Preserving (Chars, "efgh");
      --  Put (Chars); New_Line;
      pragma Assert (Extent (Chars) = 8);
      pragma Assert (Model (Chars) = "abcdefgh");

      Insert_Preserving (Chars, "ij");
      --  Put (Chars); New_Line;
      pragma Assert (Extent (Chars) = 10);
      pragma Assert (Model (Chars) = "abcdefghij");
   end Demo_Insert_Preserving_Array;

   --------------------
   -- Demo_Deletions --
   --------------------

   procedure Demo_Deletions is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Ring_Buffer (Capacity => Size);
      Value : Character;
      Deleted_Count : Element_Count;
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
      Delete (Chars, Number_To_Delete => 2, Number_Deleted => Deleted_Count);
      pragma Assert (Deleted_Count = 2);
      pragma Assert (Model (Chars) = "def");
      Delete (Chars, Number_To_Delete => 1, Number_Deleted => Deleted_Count);
      pragma Assert (Deleted_Count = 1);
      pragma Assert (Model (Chars) = "ef");
      Delete (Chars, Number_To_Delete => 3, Number_Deleted => Deleted_Count);
      pragma Assert (Deleted_Count = 2);
      pragma Assert (Model (Chars) = "");
      Delete (Chars, Number_To_Delete => 2, Number_Deleted => Deleted_Count);
      pragma Assert (Deleted_Count = 0);
      pragma Assert (Model (Chars) = "");
   end Demo_Deletions;

   ---------------
   -- Demo_Copy --
   ---------------

   procedure Demo_Copy is
      Size   : constant Positive_Element_Count := 10; -- arbitrary
      Chars  : Ring_Buffer (Capacity => Size);
   begin
      Put_Line ("Demo Copy");
      pragma Assert (Empty (Chars));

      Insert_Preserving (Chars, 'a');
      Insert_Preserving (Chars, 'b');
      Insert_Preserving (Chars, 'c');
      Insert_Preserving (Chars, 'd');
      Insert_Preserving (Chars, 'e');
      Insert_Preserving (Chars, 'f');
      Insert_Preserving (Chars, 'g');
      Insert_Preserving (Chars, 'h');
      Insert_Preserving (Chars, 'i');
      Insert_Preserving (Chars, 'j');

      pragma Assert (Model (Chars) = "abcdefghij");
      pragma Assert (Model (Chars) (Size) = 'j');
      pragma Assert (Latest_Insertion (Chars) = 'j');
      pragma Assert (Oldest_Insertion (Chars) = 'a');
      pragma Assert (not Empty (Chars));
      pragma Assert (Full (Chars));
      pragma Assert (Extent (Chars) = Size);

      declare
         Temp : Ring_Buffer (Capacity => Size);
      begin
         Copy (Chars, Target => Temp);
         pragma Assert (Chars = Temp);
         pragma Assert (Model (Temp) = Model (Chars));
         pragma Assert (Model (Temp) = "abcdefghij");
         pragma Assert (Full (Temp));
         pragma Assert (not Empty (Temp));
         pragma Assert (Extent (Temp) = Size);
         pragma Assert (Front (Temp) = 1);
         pragma Assert (Latest_Insertion (Temp) = 'j');
         pragma Assert (Oldest_Insertion (Temp) = 'a');
      end;
   end Demo_Copy;

   ---------------------------------------
   -- Demo_Insert_Preserving_and_Remove --
   ---------------------------------------

   procedure Demo_Insert_Preserving_and_Remove is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Ring_Buffer (Capacity => Size);
      Value : Character;
   begin
      Put_Line ("Demo Insert_Preserving");
      pragma Assert (Empty (Chars));
      Insert_Preserving (Chars, 'a');
      Insert_Preserving (Chars, 'b');
      Insert_Preserving (Chars, 'c');
      Remove (Chars, Value);
      pragma Assert (Value = 'a');
      Remove (Chars, Value);
      pragma Assert (Value = 'b');
      Remove (Chars, Value);
      pragma Assert (Value = 'c');
      pragma Assert (Empty (Chars));
   end Demo_Insert_Preserving_and_Remove;

   ----------------------------------
   -- Demo_Insert_Overwriting_Loop --
   ----------------------------------

   procedure Demo_Insert_Overwriting_Loop is
      Size  : constant Positive_Element_Count := 10;
      Chars : Ring_Buffer (Capacity => Size);
   begin
      Put_Line ("Demo Insert with overwriting, in a loop");
      pragma Assert (Empty (Chars));
      --  insert 20 chars, ie more than capacity, thus overwriting
      for C in Character range 'a' .. 't' loop
         Insert (Chars, C);
      end loop;
      pragma Assert (Full (Chars));
      --  the first 10 characters are "abcdefghij", because Capacity is
      --  arbitrarily set to 10. They are then replaced by 10 more, leaving
      --  those 10 characters in the buffer, ie "klmnopqrst"
      pragma Assert (Model (Chars) = "klmnopqrst");
   end Demo_Insert_Overwriting_Loop;

   ------------------------------------
   -- Demo_Insert_Overwriting_Noloop --
   ------------------------------------

   procedure Demo_Insert_Overwriting_Noloop is
      Size  : constant Positive_Element_Count := 4; -- arbitrary
      Chars : Ring_Buffer (Capacity => Size);
   begin
      Put_Line ("Demo Insert with overwriting");
      pragma Assert (Empty (Chars));
      Insert (Chars, 'a');
      pragma Assert (Model (Chars) = "a");
      Insert (Chars, 'b');
      pragma Assert (Model (Chars) = "ab");
      Insert (Chars, 'c');
      pragma Assert (Model (Chars) = "abc");
      Insert (Chars, 'd');
      pragma Assert (Model (Chars) = "abcd");
      --  now overwriting
      Insert (Chars, 'e');
      pragma Assert (Model (Chars) = "bcde");
   end Demo_Insert_Overwriting_Noloop;

   -----------------
   -- Demo_Remove --
   -----------------

   procedure Demo_Remove is
      Size  : constant Positive_Element_Count := 10; -- arbitrary
      Chars : Ring_Buffer (Capacity => Size);
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
      Chars : Ring_Buffer (Capacity => Size);
      Dummy : Character;
   begin
      Put_Line ("Demo iterations. Capacity is" & Size'Image);

      Put ("   Initially empty   : "); Put (Chars); New_Line; -- output should be ""

      Put ("   Inserted 10 chars : ");
      for C in Character range 'a' .. 'j' loop
         Insert_Preserving (Chars, C);  -- not intending to overwrite
      end loop;
      Put (Chars); New_Line;

      for K in 1 .. 5 loop
         Remove (Chars, Dummy);
      end loop;
      Put ("   Removed 5 chars   : ");
      Put (Chars); New_Line;

      for C in Character range 'u' .. 'z' loop
         Insert (Chars, C);
      end loop;
      Put ("   Inserted 6 chars  : ");  -- overwrote one
      Put (Chars); New_Line;
   end Demo_Iterations;

begin
   Demo_Iterations;
   Demo_Insert_Preserving_Array;
   Demo_Remove_Array;
   Demo_Copy;
   Demo_Deletions;
   Demo_Insert_Preserving_and_Remove;
   Demo_Remove;
   Demo_Insert_Overwriting_Loop;
   Demo_Insert_Overwriting_Noloop;

   Put_Line ("Demo complete");
end Demo_Buffers;
