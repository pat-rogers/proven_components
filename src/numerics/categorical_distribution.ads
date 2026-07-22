--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides a generator for a categorical distribution: a random
--  value of the discrete formal type Category, drawn with a likelihood
--  proportional to a relative weight assigned to each category by the user.
--  Unlike the language-defined generators, the result is not uniform but is
--  shaped by those weights; a category with zero weight is never returned.

with Ada.Streams;
with Ada.Numerics.Float_Random;

generic
   type Category is (<>);
package Categorical_Distribution with SPARK_Mode => Off is

   pragma Unevaluated_Use_Of_Old (Allow);

   type Generator is tagged limited private;

   type Weight is new Natural;

   procedure Set_Weight
     (This  : in out Generator;
      Item  : Category;
      Value : Weight)
   with
     Post => Current_Weights (This) (Item) = Value and then
             Total_Weight (This) = Total_Weight (This)'Old + (Value - Current_Weights (This)'Old (Item)) and then
             (for all V in Category =>
                (if V /= Item then
                   Current_Weights (This) (V) = Current_Weights (This)'Old (V)));
   --  Set a single weight for a single category. Individual weights can be zero.

   type Relative_Weights is array (Category) of Weight;
   --  Each component is a relative weight for the corresponding index category,
   --  to be used when computing the random result.

   procedure Set_Weights (This : in out Generator;  Values : Relative_Weights) with
     Post => Current_Weights (This) = Values and then
             Total_Weight (This) = Sum (Values);
   --  Sets all the relative weights for This. Individual weights can be zero.

   function Current_Weights (This : Generator) return Relative_Weights;
   --  Returns the current values for the relative weights assigned to This
   --  generator.

   function Total_Weight (This : Generator) return Weight with
     Post => Total_Weight'Result = Sum (Current_Weights (This));
   --  Returns the sum of the current weights defined for this generator.

   function Random (This : in out Generator) return Category with
     Pre  => Total_Weight (This) > 0,
     Post => Current_Weights (This) = Current_Weights (This)'Old and then
             Total_Weight (This) = Total_Weight (This)'Old;
   --  Returns a randomly determined category of type Category. The likelihood
   --  of a given category being returned is based on the weight assigned to
   --  that category, relative to all the other categories' weights. Requires
   --  either Set_Weight or Set_Weights to have been called previously, with at
   --  least one weight a non-zero value such that the total is non-zero at the
   --  time of the call to Random.
   --
   --  Implementation note: the body declares a local array of Category values
   --  whose number of components is Sum (This.Current_Weights). Consequently,
   --  it consumes stack space proportional to Total_Weight (This). A very large
   --  total could raise Storage_Error; use relative weight values accordingly.
   --
   --  The body also assumes Total_Weight (This) <= Natural'Last (which holds so
   --  long as Sum did not overflow when the weights were set).

   procedure Reset (This : in out Generator) with
     Post => Current_Weights (This) = Current_Weights (This)'Old;
   --  Resets the internal mechanism for generating random values (RNG). Note
   --  that the seed is the Calendar, unlike the automatic initialization for
   --  the RNG, so doing a Reset will change the sequence generated (whereas
   --  without a reset the sequence is deterministic).

   procedure Read
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      This   : out Generator);

   procedure Write
     (Stream : not null access Ada.Streams.Root_Stream_Type'Class;
      This   : in Generator);

   for Generator'Read  use Read;
   for Generator'Write use Write;

   function Sum (This : Relative_Weights) return Weight;
   --  Computes the sum of the weights.

private

   type Generator is tagged limited record
      FRG          : Ada.Numerics.Float_Random.Generator;
      Weights      : Relative_Weights := (others => 0);
      Total_Weight : Weight := 0;
   end record;

end Categorical_Distribution;
