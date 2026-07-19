--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Ada.Dynamic_Priorities;     use Ada.Dynamic_Priorities;

package body Synchronization_Mechanisms with
  SPARK_Mode => Off
is

   ------------------------
   -- Counting_Semaphore --
   ------------------------

   protected body Counting_Semaphore is

      entry Acquire when Count > 0 is
      begin
         Count := Count - 1;
      end Acquire;

      procedure Release is
      begin
         Count := Count + 1;
      end Release;

   end Counting_Semaphore;

   ----------------------
   -- Binary_Semaphore --
   ----------------------

   protected body Binary_Semaphore is

      entry Acquire when Available is
      begin
         Available := False;
      end Acquire;

      procedure Release is
      begin
         Available := True;
      end Release;

   end Binary_Semaphore;

   -----------
   -- Mutex --
   -----------

   protected body Mutex is

      entry Acquire when Available is
      begin
         Available := False;
         Current_Owner := Acquire'Caller;
      end Acquire;

      procedure Release is
      begin
         if Current_Owner = Current_Task then
            Available := True;
            Current_Owner := Null_Task_Id;
         else
            raise Protocol_Error;
         end if;
      end Release;

      procedure Reset is
      begin
         Available := True;
         Current_Owner := Null_Task_Id;
      end Reset;

   end Mutex;

   ------------------------------
   -- Priority_Extending_Mutex --
   ------------------------------

   protected body Priority_Extending_Mutex is

      entry Acquire when Available is
      begin
         Available := False;
         Current_Owner := Acquire'Caller;
         Owner_Base_Priority := Get_Priority (Current_Owner);
         Set_Priority (Ceiling, Current_Owner);
         --  The caller's base priority will now retain, after the call to
         --  Acquire returns, the elevated value it inherited (ie Ceiling).
         --  This takes effect after the end of the protected action.
      end Acquire;

      procedure Release is
      begin
         if Current_Owner = Current_Task then
            Set_Priority (Owner_Base_Priority, Current_Owner);
            --  The base priority will go back to the original value it had
            --  when the caller called Acquire. This takes effect after the
            --  end of the protected action.
            Available := True;
            Current_Owner := Null_Task_Id;
         else
            raise Protocol_Error;
         end if;
      end Release;

      procedure Reset is
      begin
         Available := True;
         Current_Owner := Null_Task_Id;
      end Reset;

   end Priority_Extending_Mutex;

   ----------------------
   --  Reentrant_Mutex --
   ----------------------

   protected body Reentrant_Mutex is

      entry Acquire when True is
      begin
         if Current_Owner = Null_Task_Id then
            Current_Owner := Acquire'Caller;
            Depth := 1;
         elsif Current_Owner = Acquire'Caller then
            Depth := Depth + 1;
         else -- held already, but not by current caller
            requeue Retry with abort;
         end if;
      end Acquire;

      procedure Release is
      begin
         if Current_Owner = Current_Task then
            Depth := Integer'Max (0, Depth - 1);
            if Depth = 0 then
               Current_Owner := Null_Task_Id;
            end if;
         else
            raise Protocol_Error;
         end if;
      end Release;

      entry Retry when Depth = 0 is
      begin
         Depth := 1;
         Current_Owner := Retry'Caller;
      end Retry;

   end Reentrant_Mutex;

   -----------
   -- Event --
   -----------

   protected body Event is

      procedure Set is
      begin
         Current_State := Up;
      end Set;

      procedure Reset is
      begin
         Current_State := Down;
      end Reset;

      procedure Toggle is
      begin
         if Current_State = Up then
            Current_State := Down;
         else
            Current_State := Up;
         end if;
      end Toggle;

      entry Wait (S : Event_States) when True is
      begin
         if S = Up then
            requeue Wait_Up with abort;
         else
            requeue Wait_Down with abort;
         end if;
      end Wait;

      function State return Event_States is
      begin
         return Current_State;
      end State;

      entry Wait_Up when Current_State = Up is
      begin
         null;
      end Wait_Up;

      entry Wait_Down when Current_State = Down is
      begin
         null;
      end Wait_Down;

   end Event;

   -----------------------
   -- Persistent_Signal --
   -----------------------

   protected body Persistent_Signal is

      procedure Send is
      begin
         Signal_Arrived := True;
      end Send;

      entry Wait when Signal_Arrived is
      begin
         Signal_Arrived := False;
      end Wait;

   end Persistent_Signal;

   -------------------
   -- Pulsed_Signal --
   -------------------

   protected body Pulsed_Signal is

      procedure Send is
      begin
         if Wait'Count > 0 then
            Signal_Arrived := True;
         end if;
      end Send;

      entry Wait when Signal_Arrived is
      begin
         Signal_Arrived := False;
      end Wait;

   end Pulsed_Signal;

   --------------------------------
   -- Readers_Writers_Controller --
   --------------------------------

   protected body Readers_Writers_Controller is

      entry Request_Reading when not Writer_Present is
      begin
         Current_Readers := Current_Readers + 1;
      end Request_Reading;

      procedure Stop_Reading is
      begin
         Current_Readers := Current_Readers - 1;
      end Stop_Reading;

      entry Request_Writing when not Writer_Present is
      begin
         Writer_Present := True;
         requeue Start_Writing;
      end Request_Writing;

      entry Start_Writing when Current_Readers = 0 is
      begin
         null;
      end Start_Writing;

      procedure Stop_Writing is
      begin
         Writer_Present := False;
      end Stop_Writing;

   end Readers_Writers_Controller;

   ------  Scope_Lock operations -----

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize (This : in out Scope_Lock) is
   begin
      This.Lock.Acquire;
   end Initialize;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (This : in out Scope_Lock) is
   begin
      This.Lock.Release;
   end Finalize;

end Synchronization_Mechanisms;
