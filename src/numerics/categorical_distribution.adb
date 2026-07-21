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
      Ada.Numerics.Float_Random.Reset (This.FRG);
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
      subtype Array_Indexes is Integer range 0 .. Integer (This.Total_Weight) - 1;
      --  We use a zero-based array index because 0.0 is a possible value
      --  for the random number generator and we are using that to compute
      --  index values.

      Weighted_Values : array (Array_Indexes) of Category;

      subtype Counting_Index is Integer range Array_Indexes'First .. Array_Indexes'Last + 1;
      --  The range is that of Weighted_Values except for 1 additional value.
      --  The loop drives the value 1 past the last valid array index but is
      --  never used as an actual index with that value.

      Next           : Counting_Index;
      Weighted_Index : Natural;
      --  The index we actually use for the function result. Weighted_Index is
      --  not of subtype Array_Indexes because we may calculate a value outside
      --  the range (hence the clamping).
      Scaled_Random  : Long_Float;
   begin
      --  For every possible Value V, assign V to a computed number of array
      --  components in Weighted_Values based on the relative weight assigned
      --  to V. The greater the weight assigned to V the greater the number of
      --  components are assigned V. Some of those weights may be zero so some
      --  Values may not be represented in the array components.
      Next := Weighted_Values'First;
      for V in Category loop
         for K in 1 .. This.Weights (V) loop
            Weighted_Values (Next) := V;
            Next := Next + 1;
         end loop;
      end loop;
      --  Now we have sequences of Values in Weighted_Values, where the
      --  sequences' lengths are proportional to the assigned weight per Value.
      --  Given that, we can compute a random index into that array and return the
      --  component Value at that index.

      --  Generate a random number in the closed interval [0.0, 1.0] and scale
      --  it by the number of possible indexes into Weighted_Values. Long_Float
      --  is used so that every Total_Weight value (up to Natural'Last) is exactly
      --  representable, keeping the conversion below within Natural's range.
      Scaled_Random := Long_Float (Random (This.FRG)) * Long_Float (This.Total_Weight);

      --  Convert to a possible Index
      Weighted_Index := Natural (Long_Float'Floor (Scaled_Random));
      if Weighted_Index > Weighted_Values'Last then --  Random (This.FRG) returned exactly 1.0
         Weighted_Index := Weighted_Values'Last;
      end if;

      return Weighted_Values (Weighted_Index);
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
      --  the RNG component auto-initializes
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

