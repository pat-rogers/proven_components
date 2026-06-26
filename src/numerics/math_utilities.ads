--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides useful math utility routines.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

package Math_Utilities
  with SPARK_Mode
is

   generic
      type Formal_Integer is range <>;
   function Range_To_Domain_Mapping
     (Value, Range_Min, Range_Max, Domain_Min, Domain_Max : Formal_Integer)
   return Formal_Integer
   with
     Pre => Range_Min < Range_Max           and then
            Domain_Min < Domain_Max         and then
            Value in Range_Min .. Range_Max and then
            --  Range_Max - Range_Min does not overflow
            (if Range_Min >= 0 then Range_Max >= Formal_Integer'First + Range_Min
                               else Range_Max <= Formal_Integer'Last + Range_Min)
            and then
            --  Domain_Max - Domain_Min does not overflow
            (if Domain_Min >= 0 then Domain_Max >= Formal_Integer'First + Domain_Min
                                else Domain_Max <= Formal_Integer'Last + Domain_Min)
            and then
            (declare
               Range_Extent  : constant Formal_Integer := Range_Max - Range_Min;
               Domain_Extent : constant Formal_Integer := Domain_Max - Domain_Min;
             begin
               --  Value - Range_Min does not overflow
               (if Range_Min >= 0 then Value >= Formal_Integer'First + Range_Min
                                  else Value <= Formal_Integer'Last + Range_Min)
               and then
               --  Range_Extent * Domain_Extent fits in the integer type (division avoids overflow)
               Range_Extent <= Formal_Integer'Last / Domain_Extent
               and then
               --  The scaled numerator, after rounding adjustment, fits in the integer type
               Value - Range_Min <= (Formal_Integer'Last - Range_Extent / 2) / Domain_Extent
               and then
               --  The final result before domain offset fits in the integer result type
               (((Value - Range_Min) * Domain_Extent) / Range_Extent) + Domain_Min in Formal_Integer),
     Post => Range_To_Domain_Mapping'Result in Domain_Min .. Domain_Max,
     Global => null,
     Inline;
   --  This function re-maps a number from one range to another. For example,
   --  a value from an analog sensor (0 .. 1023) can be converted to a range
   --  suitable for an LED's brightness (0 .. 255).
   --
   --  Unlike the Arduino version (function Map), the input and output ranges
   --  must be positive (Max > Min).
   --
   --  In the Arduino version, there is no requirement for the input value to
   --  be in the specified input range, and, consequently, the output might not
   --  be in the output range. In contrast, in this SPARK implementation the
   --  precondition and postcondition express the fact that the ranges are to
   --  be honored.
   --
   --  The implementation is based on a version of the Aduino Map() function by
   --  Paul Stoffregen. See:
   --  https://github.com/PaulStoffregen/cores/blob/e888ebd01a9f5ef71b6998c7b338c5e2b555467a/teensy4/wiring.h#L63

   generic
      type Formal_Float is digits <>;
   function Range_To_Domain_Mapping_Float
     (Value, Range_Min, Range_Max, Domain_Min, Domain_Max : Formal_Float)
   return Formal_Float
   with
     Pre  => Range_Min < Range_Max and then
             Domain_Min < Domain_Max and then
             Value in Range_Min .. Range_Max and then
             --  All inputs bounded to preclude arithmetic overflow in the body
             Range_Min >= -(Formal_Float'Last / 4.0) and then
             Range_Max <= Formal_Float'Last / 4.0 and then
             Domain_Min >= -(Formal_Float'Last / 4.0) and then
             Domain_Max <= Formal_Float'Last / 4.0 and then
             --  Float subtraction is monotone: implied by Value <= Range_Max, stated
             --  explicitly so the prover can bound the interpolation ratio in the body
             (Value - Range_Min) <= (Range_Max - Range_Min),
     Post => Range_To_Domain_Mapping_Float'Result in Domain_Min .. Domain_Max,
     Global => null,
     Inline;
   --  This function re-maps a number from one range to another.
   --
   --  The Float'Last / 4.0 bounds are the weakest symmetric exactly-representable bounds that keep
   --  every intermediate computation within the float range. The binding constraint is the body's
   --  final addition, Domain_Min + Scaled: with symmetric bound B, Domain_Extent <= 2B and
   --  Scaled = Ratio * Domain_Extent <= 1.0 * 2B = 2B, so Domain_Min + Scaled <= B + 2B = 3B.
   --  Requiring 3B <= Float'Last gives B <= Float'Last / 3. However, Float'Last / 3 is not exactly
   --  representable in IEEE 754 (3 is not a power of 2), and the nearest representable float could
   --  round upward, making 3.0 * fl(Float'Last / 3.0) > Float'Last and breaking the overflow proof.
   --  Float'Last / 4 is the next smaller power-of-2 fraction: 3 * (Float'Last / 4) = 0.75 * Float'Last.
   --
   --  The implementation is based on a version of the Arduino Map() function by
   --  Paul Stoffregen. See:
   --  https://github.com/PaulStoffregen/cores/blob/e888ebd01a9f5ef71b6998c7b338c5e2b555467a/teensy4/wiring.h#L63

   generic
      type Formal_Integer is range <>;
   function Bounded_Integer_Value
     (Value, Low, High : Formal_Integer)
   return Formal_Integer
   with
     Pre  => Low < High,
     Post => Bounded_Integer_Value'Result in Low .. High,
     Global => null,
     Inline;

   generic
      type Formal_Integer is range <>;
   procedure Bound_Integer_Value
     (Value : in out Formal_Integer; Low, High : Formal_Integer)
   with
     Pre  => Low < High,
     Post => Value in Low .. High,
     Global => null,
     Inline;

   generic
      type Formal_Float is digits <>;
   function Bounded_Floating_Value
     (Value, Low, High : Formal_Float)
   return Formal_Float
   with
     Pre  => Low < High,
     Post => Bounded_Floating_Value'Result in Low .. High,
     Global => null,
     Inline;

   generic
      type Formal_Float is digits <>;
   procedure Bound_Floating_Value
     (Value : in out Formal_Float; Low, High : Formal_Float)
   with
     Pre  => Low < High,
     Post => Value in Low .. High,
     Global => null,
     Inline;

end Math_Utilities;
