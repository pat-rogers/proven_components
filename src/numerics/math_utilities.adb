--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Math_Utilities
  with SPARK_Mode
is

   -----------------------------
   -- Range_To_Domain_Mapping --
   -----------------------------

   function Range_To_Domain_Mapping
     (Value, Range_Min, Range_Max, Domain_Min, Domain_Max : Formal_Integer)
      return Formal_Integer
   is
      Result        : Formal_Integer;
      Range_Extent  : constant Formal_Integer := Range_Max - Range_Min;
      Domain_Extent : constant Formal_Integer := Domain_Max - Domain_Min;
      Numerator     : Formal_Integer;
   begin
      Numerator := (Value - Range_Min) * Domain_Extent;
      Numerator := Numerator + (Range_Extent / 2);
      Result := (Numerator / Range_Extent) + Domain_Min;
      return Result;
   end Range_To_Domain_Mapping;


   -----------------------------------
   -- Range_To_Domain_Mapping_Float --
   -----------------------------------

   function Range_To_Domain_Mapping_Float
     (Value, Range_Min, Range_Max, Domain_Min, Domain_Max : Formal_Float)
      return Formal_Float
   is
      Range_Extent  : constant Formal_Float := Range_Max - Range_Min;
      Domain_Extent : constant Formal_Float := Domain_Max - Domain_Min;
      Numerator     : constant Formal_Float := Value - Range_Min;
      Ratio         : constant Formal_Float := Numerator / Range_Extent;
      --  Ratio is in [0, 1]: Numerator <= Range_Extent follows from the precondition
      pragma Assert (Ratio in 0.0 .. 1.0);
      Scaled        : constant Formal_Float := Ratio * Domain_Extent;
      --  Product bounded: Ratio <= 1.0 and Domain_Extent <= Float'Last / 2.0
      pragma Assert (Scaled in 0.0 .. Formal_Float'Last / 2.0);
      Result        : constant Formal_Float := Domain_Min + Scaled;
   begin
      if Result < Domain_Min then
         return Domain_Min;
      elsif Result > Domain_Max then
         return Domain_Max;
      else
         return Result;
      end if;
   end Range_To_Domain_Mapping_Float;

   ---------------------------
   -- Bounded_Integer_Value --
   ---------------------------

   function Bounded_Integer_Value (Value, Low, High : Formal_Integer) return Formal_Integer is
     (if Value < Low then Low elsif Value > High then High else Value);

   -------------------------
   -- Bound_Integer_Value --
   -------------------------

   procedure Bound_Integer_Value (Value : in out Formal_Integer; Low, High : Formal_Integer) is
   begin
      if Value < Low then
         Value := Low;
      elsif Value > High then
         Value := High;
      end if;
   end Bound_Integer_Value;

   ----------------------------
   -- Bounded_Floating_Value --
   ----------------------------

   function Bounded_Floating_Value (Value, Low, High : Formal_Float) return Formal_Float is
     (if Value < Low then Low elsif Value > High then High else Value);

   --------------------------
   -- Bound_Floating_Value --
   --------------------------

   procedure Bound_Floating_Value (Value : in out Formal_Float; Low, High : Formal_Float) is
   begin
      if Value < Low then
         Value := Low;
      elsif Value > High then
         Value := High;
      end if;
   end Bound_Floating_Value;

end Math_Utilities;
