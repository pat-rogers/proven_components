--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  The generic package provides Recursive Moving Average (RMA) filters for any
--  integer sample (ie input and output) type.

--  A Recursive Moving Average filter smooths a stream of discrete samples by
--  computing the arithmetic mean of the most recent N samples, where N is the
--  window size configured per filter object. Each new sample shifts the window
--  forward by one: the oldest sample is discarded and the new sample is added.
--
--  RMA filters are widely used in embedded and signal-processing applications
--  to suppress high-frequency noise in sensor readings (temperature, pressure,
--  ADC outputs, etc.) while preserving the underlying low-frequency signal
--  trend. They introduce a lag of approximately N/2 samples, so a smaller
--  window responds faster but smooths less, and a larger window smooths
--  more but responds more slowly to genuine signal changes.
--
--  The "recursive" qualifier refers to the running-total implementation
--  strategy: rather than summing all N samples on every insertion, the filter
--  maintains a cumulative total, adding the new sample and subtracting the
--  oldest. This gives O(1) cost per insertion regardless of window size.

--  In cases in which the running total of the input values would lead to
--  overflow, the total is limited to Accumulator'First or Accumulator'Last.
--  The average returned from function Value is limited to Sample'First or
--  Sample'Last.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Sequential_Bounded_Buffers;

generic

   type Sample is range <>;
   --  The type used for the input samples and output averages.

   type Accumulator is range <>;
   --  The type used for the running total of inputs. The intent is that this
   --  type has a larger range than that of type Sample, so that a larger total
   --  can be accommodated.

package Recursive_Moving_Average_Filters with
  SPARK_Mode,
  Always_Terminates
is

   pragma Compile_Time_Error
     (Accumulator'Size >= Long_Long_Integer'Size,
      "Accumulator must be narrower than Long_Long_Integer to allow overflow-safe intermediate arithmetic");

   subtype Filter_Window_Size is Integer range 1 .. Integer'Last / 2;

   type RMA_Filter (Window_Size : Filter_Window_Size) is limited private;

   procedure Insert (This : in out RMA_Filter;  New_Sample : Sample);
   --  Updates the new average value based on the value of New_Sample

   function Value (This : RMA_Filter) return Sample with Inline;
   --  simply returns the average value previously computed by Insert

   procedure Reset (This : out RMA_Filter) with
     Post => Value (This) = 0;

private

   package Sample_Data is new Sequential_Bounded_Buffers
     (Element => Sample, Base_Integer => Integer);
   use Sample_Data;

   type RMA_Filter (Window_Size : Filter_Window_Size) is limited record
      Samples        : Sample_Data.Ring_Buffer (Window_Size);
      Averaged_Value : Sample := 0;
      Total          : Accumulator := 0;
      --  There is no issue of accumulating round-off errors over time, unlike
      --  what would happen if we used a floating point type for the Total
   end record;

end Recursive_Moving_Average_Filters;
