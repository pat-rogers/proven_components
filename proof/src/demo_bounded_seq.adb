--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  gnatprove -Pproven_components_proof -j0 --output=oneline -u demo_bounded_seq.ads --no-inlining --level=2

with Ada.Text_IO;          use Ada.Text_IO;
with Bounded_Seq_Instance; use Bounded_Seq_Instance;

procedure Demo_Bounded_Seq with SPARK_Mode is

   pragma Warnings (Off, "* has no effect");

   procedure Put (This : Dynamic_String);
   --  Prints the String value of This on standard output, embedded
   --  within double quotes. Uses Iterable aspect of Dynamic_String.

   procedure Demo_Declarations;
   procedure Demo_Copy;
   procedure Demo_Append;
   procedure Demo_Location;
   procedure Demo_Amend;

   ---------
   -- Put --
   ---------

   procedure Put (This : Dynamic_String) is
   begin
      Put ('"');
      for C of This loop
         Put (C);
      end loop;
      Put ('"');
   end Put;

   ----------------------
   -- Demo_Declarations --
   ----------------------

   procedure Demo_Declarations is
      T1_Capacity : constant := 40; -- arbitrary
      T1_Value    : constant String := "";
      T1          : Dynamic_String := Instance (T1_Capacity, T1_Value);

      T2_Value    : constant String := "Goodbye Cruel World!!";
      T2          : Dynamic_String := Instance (T2_Value);
   begin
      pragma Assert (T1.Capacity = T1_Capacity,           "decl test 1");
      pragma Assert (T2.Capacity = T2_Value'Length,       "decl test 2");
      pragma Assert (Value (T1) = T1_Value,               "decl test 3");
      pragma Assert (Value (T1) /= Value (T2),            "decl test 4");
      pragma Assert (T1 /= T2,                            "decl test 5");
      pragma Assert (Empty (T1),                          "decl test 6");
      pragma Assert (not Empty (T2),                      "decl test 7");

      pragma Assert (Contains_At (T2, 1, 'G'),            "decl test 9");
      pragma Assert (Contains_At (T2, 5, "bye"),          "decl test 10");
      pragma Assert (Contains_At (T2, 1, Value (T2)),     "decl test 12");

      Clear (T1);
      Clear (T2);
      pragma Assert (Value (T1) = "",   "clear test 1");
      pragma Assert (Value (T2) = "",   "clear test 2");
      pragma Assert (Length (T1) = 0,   "clear test 3");
      pragma Assert (Length (T2) = 0,   "clear test 4");
   end Demo_Declarations;

   ---------------
   -- Demo_Copy --
   ---------------

   procedure Demo_Copy is
      T1_Capacity : constant := 40; -- arbitrary
      T1_Value    : constant String := "";
      T1          : constant Dynamic_String := Instance (T1_Capacity, T1_Value);

      T2_Value    : constant String := "Goodbye Cruel World!!";
      T2          : Dynamic_String := Instance (T2_Value);

      Hello       : constant String := "Hello";
   begin
      pragma Assert (Value (T1) = "",         "copy test 1");
      pragma Assert (Value (T2) /= "",        "copy test 2");

      Copy (T1, To => T2);
      pragma Assert (T2 = T1,                 "copy test 3");
      pragma Assert (Value (T2) = Value (T1), "copy test 4");

      Copy (Hello, To => T2);
      Put (T2);
      New_Line;
      pragma Assert (Value (T2) = Hello,      "copy test 5");
      pragma Assert (T2 = Hello,              "copy test 6");

      Copy ("", To => T2);
      pragma Assert (Value (T2) = "",         "copy test 8");
   end Demo_Copy;

   -----------------
   -- Demo_Append --
   -----------------

   procedure Demo_Append is
      T1_Value    : constant String := " World";
      T2_Value    : constant String := "Goodbye Cruel";
      Final_Str   : constant String := T2_Value & T1_Value & "!?";
      T1_Capacity : constant := 40;  -- arbitrary
      T2_Capacity : constant Positive := Final_Str'Length;
      T1          : constant Dynamic_String := Instance (T1_Capacity, T1_Value);
      T2          : Dynamic_String := Instance (T2_Capacity, T2_Value);
   begin
      pragma Assert (Value (T2) = T2_Value,                  "append test 0.1");
      pragma Assert (T2 = T2_Value,                          "append test 0.2");

      Append (T1, To => T2);
      pragma Assert (Value (T2) = T2_Value & T1_Value,       "append test 1");
      pragma Assert (T2 = T2_Value & T1_Value,               "append test 2");

      Append ("!", To => T2);
      pragma Assert (Value (T2) = T2_Value & T1_Value & "!", "append test 3");

      Append ('?', To => T2);
      pragma Assert (Value (T2) = Final_Str,                 "append test 4");

      Clear (T2);
      pragma Assert (Value (T2) = "",                        "append test 6");
      Append ("Hello", To => T2);
      pragma Assert (Value (T2) = "Hello",                   "append test 7");

   end Demo_Append;

   -------------------
   -- Demo_Location --
   -------------------

   procedure Demo_Location is
      T1_Capacity : constant := 40; -- arbitrary
      T1_Value    : constant String := "World";
      T1          : Dynamic_String := Instance (T1_Capacity, T1_Value);

      T2_Value    : constant String := "Goodbye World!!";
      T2          : constant Dynamic_String := Instance (T2_Value);

      Pos         : Natural;
   begin
      null;
      --  Pos := Location (T1, Within => T2);
      --  pragma Assert (Pos = 9,                         "location test 1, Pos is" & Pos'Img);

      --  Pos := Location (T1_Value, Within => T2);
      --  pragma Assert (Pos = 9,                         "location test 2, Pos is" & Pos'Img);

      --  Pos := Location ("!", Within => T2);
      --  pragma Assert (Pos = 14,                        "location test 3, Pos is" & Pos'Img);

      Pos := Location ('?', Within => T2);
      pragma Assert (Pos = 0,                         "location test 4, Pos is" & Pos'Img);

      --  Pos := Location (T2_Value, Within => T2);
      --  pragma Assert (Pos = 1,                         "location test 5, Pos is" & Pos'Img);

      Clear (T1);
      Pos := Location (T2, Within => T1);
      pragma Assert (Pos = 0,                         "location test 6, Pos is" & Pos'Img);
   end Demo_Location;

   ----------------
   -- Demo_Amend --
   ----------------

   procedure Demo_Amend is
      T1_Capacity : constant := 40; -- arbitrary, but must be >= 8
      T1_Value : constant String := "Goodbye";
      T1       : Dynamic_String := Instance (T1_Capacity, T1_Value);
   begin
      pragma Assert (Contains_At (T1, 1, T1_Value),         "amend test 1");

      Amend (T1, "boy", 5);
      pragma Assert (Contains_At (T1, 5, "boy"),            "amend test 2");
      pragma Assert (Contains_At (T1, 1, "Goodboy"),        "amend test 3");
      pragma Assert (T1 = "Goodboy",                        "amend test 4");

      --  now we extend the length of the sequence with the amended value
      Amend (T1, "boy!!", 5);
      pragma Assert (Length (T1) = 9,                       "amend test 5");
      pragma Assert (Contains_At (T1, 5, "boy!!"),           "amend test 6");
      pragma Assert (Contains_At (T1, 1, "Goodboy!!"),       "amend test 7");
      pragma Assert (T1 = "Goodboy!!",                       "amend test 8");
   end Demo_Amend;

begin
   Demo_Declarations;
   Demo_Copy;
   Demo_Append;
   Demo_Location;
   Demo_Amend;
   Put_Line ("All tests passed");
end Demo_Bounded_Seq;
