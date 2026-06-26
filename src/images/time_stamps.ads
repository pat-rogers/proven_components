--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides support for taking a "timestamp" (function Now) that
--  returns a formatted date and time in a String value. Likewise, function
--  Image allows clients to format any Time value.

--  Note that package Ada.Calendar.Formatting provides similar functionality
--  beyond that of this package.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Ada.Calendar;

package Time_Stamps with
  SPARK_Mode,
  Always_Terminates
is

   type Date_Formats is (American, European);

   Format : Date_Formats := European;
   --  Determines whether the form is
   --  "MM/DD/YYYY HH:MM:SS"
   --     or
   --  "DD/MM/YYYY HH:MM:SS"

   subtype Time_Stamp_Image is String (1 .. 19);

   function Image
     (Date         : Ada.Calendar.Time;
      Months_First : Boolean := Format = American)
      return Time_Stamp_Image
   with
     Global => null,
     Post => Image'Result (3) = '/'  and then
             Image'Result (6) = '/'  and then
             Image'Result (11) = ' ' and then
             Image'Result (14) = ':' and then
             Image'Result (17) = ':';
   --  Returns Date formatted as a time stamp. The separator positions are
   --  fixed; every other position holds a decimal digit.

   function Now (Months_First : Boolean := Format = American) return Time_Stamp_Image with
     Volatile_Function,
     Global => Ada.Calendar.Clock_Time,
     Post => Now'Result (3) = '/'  and then
             Now'Result (6) = '/'  and then
             Now'Result (11) = ' ' and then
             Now'Result (14) = ':' and then
             Now'Result (17) = ':';
   --  Returns Image applied to the current wall-clock time. A volatile
   --  function because it reads the clock.

end Time_Stamps;
