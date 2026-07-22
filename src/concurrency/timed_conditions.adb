--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Timed_Conditions is

   ----------
   -- Wait --
   ----------

   procedure Wait
     (This      : in out Timed_Condition;
      Deadline  : Time;
      Timed_Out : out Boolean)
   is
   begin
      This.Set_Handler (Deadline, Timeout_Handler.Signal_Timeout'Access);
      Suspend_Until_True (This.Caller_Unblocked);
      Wait.Timed_Out := This.Timed_Out;
   end Wait;

   ----------
   -- Wait --
   ----------

   procedure Wait
     (This      : in out Timed_Condition;
      Interval  : Time_Span;
      Timed_Out : out Boolean)
   is
   begin
      Wait (This, Clock + Interval, Timed_Out);
   end Wait;

   ------------
   -- Signal --
   ------------

   procedure Signal (This : in out Timed_Condition) is
      Handler_Was_Set : Boolean;
   begin
      This.Cancel_Handler (Handler_Was_Set);
      if Handler_Was_Set then
         --  a caller to Wait is suspended
         This.Timed_Out := False;
         Set_True (This.Caller_Unblocked);
      end if;
   end Signal;

   ---------------------
   -- Timeout_Handler --
   ---------------------

   protected body Timeout_Handler is

      --------------------
      -- Signal_Timeout --
      --------------------

      procedure Signal_Timeout (Event : in out Timing_Event) is
         This : Timed_Condition renames Timed_Condition (Timing_Event'Class (Event));
      begin
         This.Timed_Out := True;
         Set_True (This.Caller_Unblocked);
         --  note: Event's pointer to a handler becomes null automatically
      end Signal_Timeout;

   end Timeout_Handler;

end Timed_Conditions;
