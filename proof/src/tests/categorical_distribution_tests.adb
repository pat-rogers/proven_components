--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  Unit test harness for the generic package Categorical_Distribution. The harness
--  instantiates the generic for a small enumeration type and exercises each
--  public operation, reporting a PASS/FAIL line per check and a final summary.

with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Streams;               use Ada.Streams;
with Ada.Numerics.Float_Random;
with Categorical_Distribution;

procedure Categorical_Distribution_Tests is

   type Color is (Red, Green, Blue, Yellow);

   package Color_Random is new Categorical_Distribution (Category => Color);
   use Color_Random;

   RNG : Ada.Numerics.Float_Random.Generator;
   --  Source of samples for Random. Left unseeded so the sequence, and hence
   --  this test, is reproducible from run to run.

   Checks_Run    : Natural := 0;
   Checks_Failed : Natural := 0;

   --  An in-memory stream, used to exercise the Generator'Read/'Write stream
   --  attributes without touching the file system.

   Buffer_Capacity : constant := 4096;

   type Memory_Stream is new Root_Stream_Type with record
      Content : Stream_Element_Array (1 .. Buffer_Capacity);
      Written : Stream_Element_Offset := 0;
      Cursor  : Stream_Element_Offset := 0;
   end record;

   overriding
   procedure Read
     (Stream : in out Memory_Stream;
      Item   : out Stream_Element_Array;
      Last   : out Stream_Element_Offset);

   overriding
   procedure Write
     (Stream : in out Memory_Stream;
      Item   : Stream_Element_Array);

   procedure Check (Description : String;  Condition : Boolean);
   --  Records the outcome of a single check and prints one result line.

   procedure Test_Set_Weights_Roundtrip;
   --  Set_Weights followed by Current_Weights returns the same weights.

   procedure Test_Set_Weight_Single;
   --  Set_Weight changes exactly one weight, leaving the others unchanged.

   procedure Test_Total_Weight;
   --  Total_Weight equals the sum of the individual weights.

   procedure Test_Random_Respects_Zero_Weights;
   --  Random never returns a value whose weight is zero.

   procedure Test_Random_Distribution;
   --  Over many samples, observed frequencies approximate the weights.

   procedure Test_Stream_Roundtrip;
   --  Writing then reading a Generator restores its weights and total.

   ----------
   -- Read --
   ----------

   overriding
   procedure Read
     (Stream : in out Memory_Stream;
      Item   : out Stream_Element_Array;
      Last   : out Stream_Element_Offset)
   is
      Available : constant Stream_Element_Offset := Stream.Written - Stream.Cursor;
      Count     : constant Stream_Element_Offset := Stream_Element_Offset'Min (Item'Length, Available);
   begin
      for K in 0 .. Count - 1 loop
         Item (Item'First + K) := Stream.Content (Stream.Cursor + 1 + K);
      end loop;
      Stream.Cursor := Stream.Cursor + Count;
      Last := Item'First + Count - 1;
   end Read;

   -----------
   -- Write --
   -----------

   overriding
   procedure Write
     (Stream : in out Memory_Stream;
      Item   : Stream_Element_Array)
   is
   begin
      for Element of Item loop
         Stream.Written := Stream.Written + 1;
         Stream.Content (Stream.Written) := Element;
      end loop;
   end Write;

   -----------
   -- Check --
   -----------

   procedure Check (Description : String;  Condition : Boolean) is
   begin
      Checks_Run := Checks_Run + 1;
      if Condition then
         Put_Line ("PASS: " & Description);
      else
         Checks_Failed := Checks_Failed + 1;
         Put_Line ("FAIL: " & Description);
      end if;
   end Check;

   -------------------------------
   -- Test_Set_Weights_Roundtrip --
   -------------------------------

   procedure Test_Set_Weights_Roundtrip is
      G       : Generator;
      Desired : constant Relative_Weights := (Red => 1, Green => 2, Blue => 7, Yellow => 0);
   begin
      Set_Weights (G, Desired);
      Check ("Set_Weights then Current_Weights returns the same weights",
             Current_Weights (G) = Desired);
   end Test_Set_Weights_Roundtrip;

   ----------------------------
   -- Test_Set_Weight_Single --
   ----------------------------

   procedure Test_Set_Weight_Single is
      G : Generator;
   begin
      Set_Weights (G, Values => (Red => 1, Green => 2, Blue => 3, Yellow => 4));
      Set_Weight (G, Blue, Value => 9);
      Check ("Set_Weight updates the targeted value",
             Current_Weights (G) (Blue) = 9);
      Check ("Set_Weight leaves the other values unchanged",
             Current_Weights (G) (Red) = 1 and then
             Current_Weights (G) (Green) = 2 and then
             Current_Weights (G) (Yellow) = 4);
   end Test_Set_Weight_Single;

   -----------------------
   -- Test_Total_Weight --
   -----------------------

   procedure Test_Total_Weight is
      G : Generator;
   begin
      Set_Weights (G, Values => (Red => 1, Green => 2, Blue => 7, Yellow => 0));
      Check ("Total_Weight equals the sum of the individual weights",
             Total_Weight (G) = 10);
      Set_Weight (G, Yellow, Value => 5);
      Check ("Total_Weight reflects an updated single weight",
             Total_Weight (G) = 15);
   end Test_Total_Weight;

   ------------------------------------
   -- Test_Random_Respects_Zero_Weights --
   ------------------------------------

   procedure Test_Random_Respects_Zero_Weights is
      G        : Generator;
      Weights  : constant Relative_Weights := (Red => 3, Green => 0, Blue => 5, Yellow => 0);
      Sampled  : Color;
      Violated : Boolean := False;
   begin
      Set_Weights (G, Weights);
      for Trial in 1 .. 100_000 loop
         Sampled := Random (G, RNG);
         if Sampled = Green or else Sampled = Yellow then
            Violated := True;
         end if;
      end loop;
      Check ("Random never returns a zero-weight value", not Violated);
      Check ("Random leaves the weights unchanged",
             Current_Weights (G) = Weights);
   end Test_Random_Respects_Zero_Weights;

   ---------------------------------
   -- Test_Random_Distribution --
   ---------------------------------

   procedure Test_Random_Distribution is
      Samples   : constant := 200_000;
      Tolerance : constant := 0.03;
      G         : Generator;
      Weights   : constant Relative_Weights := (Red => 1, Green => 2, Blue => 7, Yellow => 0);
      Counts    : array (Color) of Natural := (others => 0);
   begin
      Set_Weights (G, Weights);
      for Trial in 1 .. Samples loop
         declare
            Sampled : constant Color := Random (G, RNG);
         begin
            Counts (Sampled) := Counts (Sampled) + 1;
         end;
      end loop;

      for C in Color loop
         declare
            Expected : constant Float := Float (Weights (C)) / Float (Total_Weight (G));
            Observed : constant Float := Float (Counts (C)) / Float (Samples);
         begin
            Check ("Observed frequency of " & C'Image & " is within tolerance of its weight",
                   abs (Observed - Expected) <= Tolerance);
         end;
      end loop;

      Check ("Larger weight is sampled more often (Blue > Green > Red)",
             Counts (Blue) > Counts (Green) and then
             Counts (Green) > Counts (Red));
   end Test_Random_Distribution;

   --------------------------
   -- Test_Stream_Roundtrip --
   --------------------------

   procedure Test_Stream_Roundtrip is
      Stream   : aliased Memory_Stream;
      Original : Generator;
      Restored : Generator;
   begin
      Set_Weights (Original, Values => (Red => 6, Green => 0, Blue => 4, Yellow => 2));
      Generator'Write (Stream'Access, Original);
      Generator'Read (Stream'Access, Restored);
      Check ("Stream roundtrip restores the weights",
             Current_Weights (Restored) = Current_Weights (Original));
      Check ("Stream roundtrip restores the total weight",
             Total_Weight (Restored) = Total_Weight (Original));
   end Test_Stream_Roundtrip;

begin
   Put_Line ("Running Categorical_Distribution unit tests");
   Put_Line ("-------------------------------------------");

   Test_Set_Weights_Roundtrip;
   Test_Set_Weight_Single;
   Test_Total_Weight;
   Test_Random_Respects_Zero_Weights;
   Test_Random_Distribution;
   Test_Stream_Roundtrip;

   New_Line;
   Put_Line ("Checks run:    " & Checks_Run'Image);
   Put_Line ("Checks failed: " & Checks_Failed'Image);

   if Checks_Failed = 0 then
      Put_Line ("Result: ALL TESTS PASSED");
   else
      Put_Line ("Result: FAILURES DETECTED");
   end if;
end Categorical_Distribution_Tests;
