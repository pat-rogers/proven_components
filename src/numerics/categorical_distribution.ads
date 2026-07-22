--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides a generator for a categorical distribution: a
--  random value of the discrete formal type Category, drawn with a likelihood
--  proportional to a relative weight assigned to each category by the user.
--  Unlike the language-defined generators, the result is not uniform but is
--  shaped by those weights; a category with zero weight is never returned.
--
--  The RNG is not stored in the distribution. The function Random takes an
--  Float_Random generator as a parameter, so the Generator holds only the
--  weights and is an ordinary SPARK object. The weight management and the
--  selection kernel (Selected_Category) are analyzed and proved; only Random
--  itself, which samples the generator, and the stream attributes have
--  SPARK_Mode set to Off.

with Ada.Streams;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Big_Numbers.Big_Integers;
use  Ada.Numerics.Big_Numbers.Big_Integers;

generic
   type Category is (<>);
package Categorical_Distribution with SPARK_Mode is

   pragma Unevaluated_Use_Of_Old (Allow);

   type Generator is private;

   type Weight is new Natural;

   type Relative_Weights is array (Category) of Weight;
   --  Each component is a relative weight for the corresponding index category,
   --  to be used when computing the random result.

   package Weight_Conversions is new Signed_Conversions (Int => Weight);
   use Weight_Conversions;

   function Mass_From (Weights : Relative_Weights;  From : Category) return Big_Integer is
     (if From = Category'Last
      then To_Big_Integer (Weights (Category'Last))
      else To_Big_Integer (Weights (From)) + Mass_From (Weights, Category'Succ (From)))
   with
     Ghost,
     Subprogram_Variant => (Increases => Category'Pos (From));
   --  The total weight of Weights (From) .. Weights (Category'Last), as a
   --  Big_Integer so the total is expressed without any risk of overflow.

   function Total_In_Range (Weights : Relative_Weights) return Boolean is
     (Mass_From (Weights, Category'First) <= To_Big_Integer (Weight'Last))
   with Ghost;
   --  True when the sum of all the weights is representable as a Weight. Every
   --  Generator maintains this as a type invariant, so its total never
   --  overflows.

   function Random
     (This   : Generator;
      Source : in out Ada.Numerics.Float_Random.Generator)
      return Category
   with
     Side_Effects,
     SPARK_Mode => Off,
     Pre => Total_Weight (This) > 0;
   --  Returns a randomly determined category of type Category. The likelihood
   --  of a given category being returned is based on the weight assigned to
   --  that category, relative to all the other categories' weights. The sample
   --  is drawn from Source. Requires either Set_Weight or Set_Weights to have
   --  been called previously, with at least one weight a non-zero value such
   --  that the total is non-zero at the time of the call.

   procedure Set_Weight (This : in out Generator;  Item : Category;  Value : Weight) with
     Pre  => Total_In_Range ((Current_Weights (This) with delta Item => Value)),
     Post => Current_Weights (This) (Item) = Value and then
             (for all V in Category =>
                (if V /= Item then Current_Weights (This) (V) = Current_Weights (This)'Old (V)));
   --  Set a single weight for a single category. Individual weights can be zero.
   --  The precondition requires the resulting total to remain representable.

   procedure Set_Weights (This : out Generator;  Values : Relative_Weights) with
     Pre  => Total_In_Range (Values),
     Post => Current_Weights (This) = Values and then
             Total_Weight (This) = Sum (Values);
   --  Sets all the relative weights for This. Individual weights can be zero.
   --  The precondition requires the total of Values to be representable.

   function Current_Weights (This : Generator) return Relative_Weights;
   --  Returns the current values for the relative weights assigned to This
   --  generator.

   function Total_Weight (This : Generator) return Weight with
     Post => Total_Weight'Result = Sum (Current_Weights (This));
   --  Returns the sum of the current weights defined for this generator.

   function Sum (Weights : Relative_Weights) return Weight with
     Pre  => Total_In_Range (Weights),
     Post => To_Big_Integer (Sum'Result) = Mass_From (Weights, Category'First);
   --  Computes the sum of the weights.

   function Selected_Category (Weights : Relative_Weights;  Index : Weight) return Category with
     Pre  => To_Big_Integer (Index) < Mass_From (Weights, Category'First),
     Post => Weights (Selected_Category'Result) > 0;
   --  The proven selection kernel: returns the category whose cumulative-weight
   --  bucket contains Index. The precondition requires Index to lie below the
   --  total weight; the result is guaranteed to have a positive weight, so a
   --  zero-weight category is never returned.

   procedure Read
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      This   : out Generator);

   procedure Write
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      This   : in Generator);

   for Generator'Read  use Read;
   for Generator'Write use Write;

private

   type Generator is record
      Weights : Relative_Weights := (others => 0);
   end record with
      Type_Invariant => Total_In_Range (Generator.Weights);

end Categorical_Distribution;
