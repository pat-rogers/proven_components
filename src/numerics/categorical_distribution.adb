--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Categorical_Distribution is

   use Ada.Numerics.Float_Random;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : in out Generator) is
   begin
      Reset (This.FRG);
   end Reset;

   -----------------
   -- Set_Weights --
   -----------------

   procedure Set_Weights (This : in out Generator;  Values : Relative_Weights) is
   begin
      This.Weights := Values;
      This.Total_Weight := Sum (This.Weights);
   end Set_Weights;

   ----------------
   -- Set_Weight --
   ----------------

   procedure Set_Weight
     (This  : in out Generator;
      Item  : Category;
      Value : Weight)
   is
   begin
      This.Weights (Item) := Value;
      This.Total_Weight := Sum (This.Weights);
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
     (This.Total_Weight);

   ------------
   -- Random --
   ------------

   function Random (This : in out Generator) return Category is
      subtype Indexes is Integer range 0 .. Integer (This.Total_Weight) - 1;
      --  we use a zero-based array index because 0.0 is a possible value
      --  for the random number generator and we are using that to compute
      --  index values.

      Weighted_Values : array (Indexes) of Category;
      Index           : Integer range Weighted_Values'First .. Weighted_Values'Last + 1;
      Random_Number   : Float;
   begin
      --  For every possible Value V, assign V to a computed number of array
      --  components in Weighted_Values based on the relative weight assigned
      --  to V. The greater the weight assigned to V the greater the number of
      --  components are assigned V. Some of those weights may be zero so some
      --  Values may not be represented in the array components.
      Index := Weighted_Values'First;
      for V in Category loop
         for K in 1 .. This.Weights (V) loop
            Weighted_Values (Index) := V;
            Index := Index + 1;
         end loop;
      end loop;
      --  Now we have sequences of Values in Weighted_Values, where the
      --  sequences' lengths are proportional to the assigned weight per Value.
      --  Given that, we can compute a random index into that array and return the
      --  component Value at that index.

      --  Generate a random number in the closed interval [0.0, 1.0] and scale
      --  it by the number of possible indexes into Weighted_Values.
      Random_Number := Random (This.FRG) * Float (This.Total_Weight);
      --  Convert to an actual Index
      Index := Indexes (Float'Floor (Random_Number));
      if Index > Weighted_Values'Last then --  Random (This.FRG) returned exactly 1.0
         Index := Weighted_Values'Last;
      end if;

      return Weighted_Values (Index);
   end Random;

   ---------
   -- Sum --
   ---------

   function Sum (This : Relative_Weights) return Weight is
      Result : Weight := 0;
   begin
      for K in This'Range loop
         Result := Result + This (K);
      end loop;
      return Result;
   end Sum;

   ----------
   -- Read --
   ----------

   procedure Read
      (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
       This   : out Generator)
   is
   begin
      Relative_Weights'Read (Stream, This.Weights);
      This.Total_Weight := Sum (This.Weights);
      Reset (This.FRG);
   end Read;

   -----------
   -- Write --
   -----------

   procedure Write
      (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
       This   : Generator)
   is
   begin
      Relative_Weights'Write (Stream, This.Weights);
   end Write;

end Categorical_Distribution;

