--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package provides Simple Moving Average (SMA) filters for any
--  sample type convertible to a floating-point output type.

--  A Simple Moving Average filter smooths a stream of samples by computing the
--  arithmetic mean of the most recent N samples, where N is the window size
--  configured per filter object. Each new sample shifts the window forward by
--  one: the oldest sample is discarded and the new sample is added.
--
--  SMA filters are widely used in embedded and signal-processing applications
--  to suppress high-frequency noise in sensor readings while preserving the
--  underlying low-frequency signal trend. Like all moving-average filters, they
--  introduce a lag of approximately N/2 samples: a smaller window responds
--  faster but smooths less, while a larger window smooths more but responds
--  more slowly to genuine signal changes.
--
--  Unlike a Recursive Moving Average (RMA) filter, this implementation does
--  not maintain a running total across insertions. Instead it recomputes the
--  sum from all currently buffered samples on every insertion. This trades
--  higher per-insertion cost (O(N) rather than O(1)) for freedom from
--  long-term accumulation of rounding errors or integer overflow in the total.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Sequential_Bounded_Buffers;

generic

   type Sample is private;
   --  the type used for the input samples

   type Output is digits <>;
   --  the type used for the output average provided

   with function As_Output (Input : Sample) return Output;
   --  a conversion routine from Sample input value to the Output type

package Simple_Moving_Average_Filters with
  SPARK_Mode,
  Always_Terminates
is

   subtype Filter_Window_Size is Integer range 1 .. Integer'Last / 2;

   type SMA_Filter (Window_Size : Filter_Window_Size) is limited private;

   procedure Insert (This : in out SMA_Filter;  New_Sample : Sample);

   function Value (This : SMA_Filter) return Output;

   procedure Reset (This : out SMA_Filter) with
     Post => Value (This) = 0.0;

private

   package Sample_Data is new Sequential_Bounded_Buffers
     (Element => Sample, Base_Integer => Integer);
   use Sample_Data;

   type SMA_Filter (Window_Size : Filter_Window_Size) is limited record
      Samples  : Sample_Data.Ring_Buffer (Window_Size);
      MA_Value : Output := 0.0;
   end record;

end Simple_Moving_Average_Filters;
