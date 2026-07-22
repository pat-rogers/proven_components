--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Time_Stamps with SPARK_Mode is

   Seconds_Per_Min  : constant := 60;
   Seconds_Per_Hour : constant := 3600;

   type Ticks is range 0 .. 86_400;

   Initial_Image : constant Time_Stamp_Image := "00/00/0000 00:00:00";

   --  slices in the resulting Time_Stamp_Image string
   subtype Year_Digits    is Integer range 7 .. 10;
   subtype Hours_Digits   is Integer range 12 .. 13;
   subtype Minutes_Digits is Integer range 15 .. 16;
   subtype Seconds_Digits is Integer range 18 .. 19;

   pragma Compile_Time_Error (Seconds_Digits'Last /= Time_Stamp_Image'Last, "Result string length mismatch");

   -----------
   -- Digit --
   -----------

   function Digit (Value : Natural) return Character is
     (Character'Val (Character'Pos ('0') + Value))
   with
     Global => null,
     Pre  => Value <= 9,
     Post => Digit'Result in '0' .. '9';
   --  The decimal-digit character denoting Value.

   -----------
   -- Image --
   -----------

   function Image
     (Date         : Ada.Calendar.Time;
      Months_First : Boolean := Format = American)
      return Time_Stamp_Image
   is
      Month_Tens : constant Integer := (if Months_First then 1 else 4);
      Month_Ones : constant Integer := (if Months_First then 2 else 5);
      Day_Tens   : constant Integer := (if Months_First then 4 else 1);
      Day_Ones   : constant Integer := (if Months_First then 5 else 2);

      Current_Year       : Ada.Calendar.Year_Number;
      Current_Month      : Ada.Calendar.Month_Number;
      Current_Day        : Ada.Calendar.Day_Number;
      Secs_Past_Midnight : Ticks;
      Secs_This_Hour     : Integer range 0 .. 3599;
      Current_Hours      : Integer range 0 .. 24;
      Current_Minutes    : Integer range 0 .. 59;
      Current_Seconds    : Integer range 0 .. 59;
      Result             : Time_Stamp_Image := Initial_Image;
      The_Seconds        : Ada.Calendar.Day_Duration;
   begin
      pragma Warnings (Off, "no Global contract");
      pragma Warnings (Off, "no Always_Terminates aspect");
      Ada.Calendar.Split
        (Date,
         Year    => Current_Year,
         Month   => Current_Month,
         Day     => Current_Day,
         Seconds => The_Seconds);
      pragma Warnings (On);

      Secs_Past_Midnight := Ticks (The_Seconds);

      Current_Hours   := Integer (Secs_Past_Midnight / Ticks (Seconds_Per_Hour));
      Secs_This_Hour  := Integer (Secs_Past_Midnight mod Ticks (Seconds_Per_Hour));
      Current_Minutes := Secs_This_Hour / Seconds_Per_Min;
      Current_Seconds := Secs_This_Hour mod Seconds_Per_Min;

      Result (Month_Tens) := Digit (Current_Month / 10);
      Result (Month_Ones) := Digit (Current_Month mod 10);

      Result (Day_Tens) := Digit (Current_Day / 10);
      Result (Day_Ones) := Digit (Current_Day mod 10);

      Result (Year_Digits) := Digit (Current_Year / 1000) &
                              Digit ((Current_Year / 100) mod 10) &
                              Digit ((Current_Year / 10) mod 10) &
                              Digit (Current_Year mod 10);

      Result (Hours_Digits) := Digit (Current_Hours / 10) & Digit (Current_Hours mod 10);
      Result (Minutes_Digits) := Digit (Current_Minutes / 10) & Digit (Current_Minutes mod 10);
      Result (Seconds_Digits) := Digit (Current_Seconds / 10) & Digit (Current_Seconds mod 10);

      return Result;
   end Image;

   ---------
   -- Now --
   ---------

   function Now (Months_First : Boolean := Format = American) return Time_Stamp_Image is
      --  The wall clock is read into a local constant: a volatile function
      --  call may not appear directly as an actual parameter.
      Right_Now : constant Ada.Calendar.Time := Ada.Calendar.Clock;
   begin
      return Image (Right_Now, Months_First);
   end Now;

end Time_Stamps;
