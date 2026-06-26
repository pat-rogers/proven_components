--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Simple_Moving_Average_Filters with
  SPARK_Mode
is

   function New_Average (This : SMA_Filter) return Output;

   -----------
   -- Value --
   -----------

   function Value (This : SMA_Filter) return Output is
     (This.MA_Value);

   ------------
   -- Insert --
   ------------

   procedure Insert (This : in out SMA_Filter;  New_Sample : Sample) is
   begin
      Insert (This.Samples, New_Sample);
      This.MA_Value := New_Average (This);
   end Insert;

   -----------------
   -- New_Average --
   -----------------

   function New_Average (This : SMA_Filter) return Output is
      Result : Output := 0.0;
   begin
      for Value of This.Samples loop
         Result := Result + As_Output (Value);
      end loop;

      if Extent (This.Samples) > 1 then
         Result := Result / Output (Extent (This.Samples));
      end if;
      return Result;
   end New_Average;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : out SMA_Filter) is
   begin
      Reset (This.Samples);
      This.MA_Value := 0.0;
   end Reset;

end Simple_Moving_Average_Filters;
