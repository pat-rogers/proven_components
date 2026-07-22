--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides an abstract data type that allows client tasks to
--  block on objects of the type, waiting for resumption signals from other
--  components, for at most a specified amount of time per object. This
--  "timeout" capability has been available in Ada from the beginning, via
--  select statements containing timed entry calls. But select statements
--  and timed calls are not included within the Ravenscar and Jorvik tasking
--  subsets. This abstraction will provide some of the functionality of timed
--  entry calls, with an implementation consistent with the Ravenscar and Jorvik
--  subsets.

--  See https://www.adacore.com/blog/blocking-with-a-timeout-in-ravenscar-jorvik

with Ada.Real_Time;                use Ada.Real_Time;
with Ada.Real_Time.Timing_Events;  use Ada.Real_Time.Timing_Events;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with System;

package Timed_Conditions is

   type Timed_Condition is limited private;

   procedure Wait
     (This      : in out Timed_Condition;
      Deadline  : Time;
      Timed_Out : out Boolean);

   procedure Wait
     (This      : in out Timed_Condition;
      Interval  : Time_Span;
      Timed_Out : out Boolean);

   procedure Signal (This : in out Timed_Condition);

private

   type Timed_Condition is new Timing_Event with record
      Timed_Out        : Boolean := False;
      Caller_Unblocked : Suspension_Object;
   end record;

   protected Timeout_Handler with
      Interrupt_Priority => System.Interrupt_Priority'First
   is
      procedure Signal_Timeout (Event : in out Timing_Event);
   end Timeout_Handler;
   --  A shared, global PO defining the timing event handler procedure. All
   --  objects of type Timed_Condition use this one handler. Each execution of
   --  the procedure will necessarily execute at Interrupt_Priority'First, so
   --  there's no reason to have a handler per-object.

end Timed_Conditions;
