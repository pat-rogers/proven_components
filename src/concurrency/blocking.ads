--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides mechanisms implementing tasking synchronization
--  protocols to be applied to application (client caller) tasks. That
--  protocol might be mutual exclusion, but can be anything.
--
--  Specifically, objects of these types block caller tasks until the
--  synchronization protocol allows them to return from the call, thereby
--  allowing them to resume execution only when consistent with the protocol.
--  (We are using the term "block" loosely here, meaning the caller task is
--  not allowed to return from the call. This blocking is distinct from the
--  potentially blocking operations prohibited by the language.)

--  Note that protected declarations in this package are protected types,
--  rather than protected objects, because the facilities they provide are
--  application-independent. The mutex facility is a good example: only the
--  application developer knows how many sections of code will require mutually
--  exclusive access, i.e., how many mutex objects will be required.

--  All but the most trivial of the protected types and declarations are not in
--  the SPARK subset, and the package has disallowed dependencies, so SPARK_Mode
--  is Off rather than Auto.

with Ada.Finalization;
with Ada.Task_Identification; use Ada.Task_Identification;
with System;

package Blocking with
  SPARK_Mode => Off
is

   Protocol_Error : exception;
   --  Raised when client tasks do not follow the protocol required by the
   --  given blocking abstraction. For example, it is raised if the abstraction
   --  requires that the task that acquired a lock be the task that releases it.

   ------------------------------  Signals  -----------------------------------

   --  A type allowing one task to "signal" some other task to allow the other
   --  task to continue execution. The signal is retained until a caller calls
   --  Wait, i.e., it is retained whether or not a caller is currently waiting
   --  for it.

   protected type Persistent_Signal is
      procedure Send;
      entry Wait;
   private
      Signal_Arrived : Boolean := False;
   end Persistent_Signal;

   --  A type allowing one task to send a "signal" some other task to allow
   --  the other task to continue execution. When a signal arrives, it is NOT
   --  retained if no caller is currently waiting for it.

   protected type Pulsed_Signal is
      procedure Send;
      entry Wait;
   private
      Signal_Arrived : Boolean := False;
   end Pulsed_Signal;

   ----------------------------  Semaphores  ----------------------------------

   --  A basic counting semaphore for concurrent programming.

   protected type Counting_Semaphore (Initial_Count : Natural) is
      entry Acquire;
      procedure Release;
   private
      Count : Natural := Initial_Count;
   end Counting_Semaphore;

   --  A basic binary semaphore for concurrent programming.

   protected type Binary_Semaphore (Initially_Available : Boolean) is
      entry Acquire;
      procedure Release;
   private
      Available : Boolean := Initially_Available;
   end Binary_Semaphore;

   ------------------------------  Mutexes  -----------------------------------

   --  A basic mutex for concurrent programming.

   protected type Mutex is
      entry Acquire;
      procedure Release;
      --  Release raises Protocol_Error if the caller is not the current owner
      procedure Reset;
      --  Takes the object back to the initial elaborated state
   private
      Available     : Boolean := True;
      Current_Owner : Task_Id := Null_Task_Id;
   end Mutex;

   --  A mutex type that provides priority inheritance like that of an
   --  OS-defined mutex.
   --
   --  See https://www.adacore.com/blog/priority-extending-mutexes for a
   --  detailed discussion.

   protected type Priority_Extending_Mutex
     (Ceiling : System.Priority)
   with
      Priority => Ceiling
   is

      entry Acquire;
      --  The caller's base priority is set to the value of Ceiling and the
      --  caller is the "current owner" of the mutex.

      procedure Release;
      --  The mutex lock is relinquished and the caller's base priority is set
      --  back to the value it had at the point of the call to Acquire. Raises
      --  Protocol_Error if the current owner is not the task calling Release

      procedure Reset;
      --  Takes the object back to the initial elaborated state

   private
      Available           : Boolean := True;
      Current_Owner       : Task_Id := Null_Task_Id;
      Owner_Base_Priority : System.Priority;
   end Priority_Extending_Mutex;

   --  A mutex type that allows the current holder of a given mutex to
   --  "re-acquire" that mutex without blocking.

   protected type Reentrant_Mutex is

      entry Acquire;
      --  Acquires the mutex if available. Blocks the caller if another
      --  thread already owns the mutex. However, if the current caller
      --  already owns the mutex that fact is noted and the caller
      --  continues without blocking.

      procedure Release;
      --  Relinquishes the mutex if the number of calls to Release matches the
      --  number of prior calls to Seize. Raises Protocol_Error if the caller
      --  is not the current holder of the mutex.

   private

      entry Retry;
      --  Internal target of requeue when the mutex is already owned.

      Depth : Natural := 0;
      --  Number of calls to Seize for a given holder. A value of zero
      --  indicates than no task currently holds the mutex.

      Current_Owner : Task_Id := Null_Task_Id;
      --  The current holder of the mutex, initially none.

   end Reentrant_Mutex;

   -----------------------------  Scope Locks  ----------------------------------

   --  A lock that automatically acquires the referenced Binary_Semaphore
   --  on initialization and releases it during finalization. Simply declare an
   --  object of the Scope_Lock type within a declarative part to ensure mutual
   --  exclusive access to all the data and routines declared within that
   --  declarative part. The Lock itself (the discriminant value) must be
   --  declared outside of the declarative part in which the Scope_Lock object
   --  is located.
   --
   --  See https://www.adacore.com/blog/gem-70 for a detailed explanation.
   --
   --  For example:
   --
   --       S : Binary_Semaphore;
   --       X : Obj; -- data to be protected from race conditions
   --
   --       procedure Update_X_1 is
   --          Lock : Scope_lock (S'Access);
   --       begin
   --           -- update X without race conditions...
   --       end Update_X_1;
   --
   --       procedure Update_X_2 is
   --          Lock : Scope_lock (S'Access);
   --       begin
   --           -- update X without race conditions...
   --       end Update_X_2;

   type Scope_Lock (Lock : access Binary_Semaphore) is tagged limited private;

   -----------------------------  Readers/Writers Protocol  ----------------------------------

   --  A type providing the readers-writers access protocol.

   protected type Readers_Writers_Controller is
      entry Request_Reading;
      entry Request_Writing;
      procedure Stop_Reading;
      procedure Stop_Writing;
   private
      entry Start_Writing;
      Current_Readers : Natural := 0;
      Writer_Present  : Boolean := False;
   end Readers_Writers_Controller;

   -------------------------------  Events  -----------------------------------

   --  A type providing "events" that tasks can set (and clear and toggle),
   --  and await.

   type Event_States is (Up, Down);

   protected type Event (Initial_State : Event_States := Down) is
      procedure Set    with Post => State = Up;
      procedure Reset  with Post => State = Down;
      procedure Toggle with Post => State /= State'Old;
      entry Wait (S : Event_States);
      function State return Event_States;
   private
      entry Wait_Up;
      entry Wait_Down;
      Current_State : Event_States := Initial_State;
   end Event;

private

   type Scope_Lock (Lock : access Binary_Semaphore) is
      new Ada.Finalization.Limited_Controlled with null record;

   overriding procedure Initialize (This : in out Scope_Lock);
   overriding procedure Finalize (This : in out Scope_Lock);

end Blocking;
