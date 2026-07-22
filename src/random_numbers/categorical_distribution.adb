--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Ada.Streams;  use Ada.Streams;
with Ada.Unchecked_Conversion;
with System;

package body Categorical_Distribution with SPARK_Mode is

   -----------------------
   -- Selected_Category --
   -----------------------

   function Selected_Category (Weights : Relative_Weights;  Index : Weight) return Category is
      Remaining : Weight := Index;
      --  The residual offset into the cumulative-weight buckets still to be
      --  crossed. It never underflows: it is decreased by Weights (V) only when
      --  Weights (V) <= Remaining.

      Result : Category;
   begin
      for V in Category loop
         --  Remaining is still less than the weight remaining from V onward, so
         --  the crossing bucket lies at or after V; in particular the exit below
         --  must be taken by the time V reaches Category'Last.
         pragma Loop_Invariant (To_Big_Integer (Remaining) < Mass_From (Weights, V));

         Result := V;
         exit when Weights (V) > Remaining;
         Remaining := Remaining - Weights (V);
      end loop;

      --  The loop always exits via the guard (never by running past
      --  Category'Last), so Result holds the crossing bucket, whose weight
      --  exceeds the non-negative Remaining and is therefore positive.
      return Result;
   end Selected_Category;

   ------------
   -- Random --
   ------------

   function Random
     (This   : Generator;
      Source : in out Ada.Numerics.Float_Random.Generator)
      return Category
   with SPARK_Mode => Off
   is
      use Ada.Numerics.Float_Random;

      Total   : constant Weight := Sum (This.Weights);
      Scaled  : constant Long_Float := Long_Float (Random (Source)) * Long_Float (Total);
      --  The draw is in the closed interval [0.0, 1.0]; scaling by Total spreads
      --  it across the cumulative weight range. Long_Float is used so that every
      --  Total value (up to Natural'Last) is exactly representable, keeping the
      --  conversion below within Natural's range.

      Floored : constant Long_Float := Long_Float'Floor (Scaled);
      Index   : Weight;
   begin
      --  Floor yields a bucket index in 0 .. Total. Clamp the endpoint case (the
      --  draw returned exactly 1.0) down to the last valid index.
      if Floored >= Long_Float (Total) then
         Index := Total - 1;
      else
         Index := Weight (Floored);
      end if;

      return Selected_Category (This.Weights, Index);
   end Random;

   -----------------
   -- Set_Weights --
   -----------------

   procedure Set_Weights (This : out Generator;  Values : Relative_Weights) is
   begin
      This.Weights := Values;
   end Set_Weights;

   ----------------
   -- Set_Weight --
   ----------------

   procedure Set_Weight (This : in out Generator;  Item : Category;  Value : Weight) is
   begin
      This.Weights (Item) := Value;
   end Set_Weight;

   ---------------------
   -- Current_Weights --
   ---------------------

   function Current_Weights (This : Generator) return Relative_Weights is
     (This.Weights);

   ------------------
   -- Total_Weight --
   ------------------

   function Total_Weight (This : Generator) return Weight is
     (Sum (This.Weights));

   ---------
   -- Sum --
   ---------

   function Sum (Weights : Relative_Weights) return Weight is
      Result : Weight := 0;
   begin
      for V in reverse Category loop
         Result := Result + Weights (V);
         --  Result now holds the mass from V onward.
         pragma Loop_Invariant (To_Big_Integer (Result) = Mass_From (Weights, V));
      end loop;
      return Result;
   end Sum;

   ----------
   -- Read --
   ----------

   procedure Read
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      This   : out Generator)
   with SPARK_Mode => Off
   is
      Item_Size : constant Ada.Streams.Stream_Element_Offset := Generator'Object_Size / Stream_Element'Size;
      type SEA_Pointer is access all Ada.Streams.Stream_Element_Array (1 .. Item_Size);
      function As_SEA_Pointer is new Ada.Unchecked_Conversion (System.Address, SEA_Pointer);
      Last : Ada.Streams.Stream_Element_Offset;
   begin
      --  Read the whole generator as one block, overlaying its storage.
      Ada.Streams.Read (Stream.all, As_SEA_Pointer (This'Address).all, Last);
   end Read;

   -----------
   -- Write --
   -----------

   procedure Write
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      This   : Generator)
   with SPARK_Mode => Off
   is
      Item_Size : constant Ada.Streams.Stream_Element_Offset := Generator'Object_Size / Stream_Element'Size;
      type SEA_Pointer is access all Ada.Streams.Stream_Element_Array (1 .. Item_Size);
      function As_SEA_Pointer is new Ada.Unchecked_Conversion (System.Address, SEA_Pointer);
   begin
      --  Write the whole generator as one block, overlaying its storage.
      Ada.Streams.Write (Stream.all, As_SEA_Pointer (This'Address).all);
   end Write;

end Categorical_Distribution;
