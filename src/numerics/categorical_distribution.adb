--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Categorical_Distribution with SPARK_Mode is

   -----------------------
   -- Selected_Category --
   -----------------------

   function Selected_Category (Weights : Relative_Weights;  Index : Weight) return Category is
      Remaining : Weight := Index;
      --  The residual offset into the cumulative-weight buckets still to be
      --  crossed. It never underflows: it is decreased by Weights (V) only when
      --  Weights (V) <= Remaining.
   begin
      for V in Category loop
         --  Remaining is still less than the weight remaining from V onward, so
         --  a crossing bucket lies at or after V; in particular the guard below
         --  must hold by the time V reaches Category'Last.
         pragma Loop_Invariant (To_Big_Integer (Remaining) < Mass_From (Weights, V));

         if Weights (V) > Remaining then
            return V;
         end if;
         Remaining := Remaining - Weights (V);
      end loop;

      --  Unreachable: at V = Category'Last the invariant gives
      --  Remaining < Weights (Category'Last), so the guard returns above.
      raise Program_Error;
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
      Total   : constant Weight := Sum (This.Weights);
      Scaled  : constant Long_Float :=
        Long_Float (Ada.Numerics.Float_Random.Random (Source)) * Long_Float (Total);
      --  The draw is in the closed interval [0.0, 1.0]; scaling by Total spreads
      --  it across the cumulative weight range. Long_Float is used so that every
      --  Total value (up to Natural'Last) is exactly representable, keeping the
      --  conversion below within Natural's range.

      Floored : constant Long_Float := Long_Float'Floor (Scaled);

      Index : Weight;
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

   function Current_Weights (This : Generator) return Relative_Weights is (This.Weights);

   ------------------
   -- Total_Weight --
   ------------------

   function Total_Weight (This : Generator) return Weight is (Sum (This.Weights));

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
   begin
      Relative_Weights'Read (Stream, This.Weights);
   end Read;

   -----------
   -- Write --
   -----------

   procedure Write
      (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
       This   : Generator)
   with SPARK_Mode => Off
   is
   begin
      Relative_Weights'Write (Stream, This.Weights);
   end Write;

end Categorical_Distribution;
