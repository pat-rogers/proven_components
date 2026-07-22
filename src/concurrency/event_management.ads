--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides a means for blocking a calling task until/unless any
--  one of an arbitrary set of "events" is "signaled."

--  NOTE: this implementation works with either priority-ordered or FIFO-ordered
--  queuing.

--  See https://www.adacore.com/blog/on-the-benefits-of-families

generic
   type Event is (<>);
package Event_Management is

   type Manager is limited private;

   type Event_List is array (Positive range <>) of Event;

   procedure Wait
     (This         : in out Manager;
      Any_Of_These :        Event_List;
      Enabler      :    out Event)
   with
     Pre => Any_Of_These'Length > 0;
   --  Block until/unless any one of the events in Any_Of_These has
   --  been signaled. The one enabling event will be returned in the
   --  Enabler parameter, and is cleared internally as Wait exits.
   --  Any other signaled events remain signaled. Note that,
   --  when Signal is called, the events within the aggregate
   --  Any_of_These are checked (for whether they are signaled)
   --  in the order they appear in the aggregate. We use a precondition
   --  on Wait because the formal parameter Enabler is mode out, and
   --  type Event is a discrete type. As such, if there was nothing in
   --  the list to await, the call would return immediately, with
   --  Enabler's value undefined.

   procedure Wait
     (This     : in out Manager;
      This_One : Event);
   --  Block until/unless the specified event has been signaled.
   --  This procedure is a convenience routine that can be used
   --  instead of an aggregate with only one event component.

   procedure Signal
     (This         : in out Manager;
      All_Of_These : Event_List);
   --  Indicate that all of the events in All_Of_These are now signaled. The
   --  events remain signaled until cleared by Wait. We don't need a similar
   --  precondition like that on procedure Wait because, for Signal, doing
   --  nothing is what the empty list requests.

   procedure Signal
     (This     : in out Manager;
      This_One : Event);
   --  Indicate that event This_One is now signaled. The event
   --  remains signaled until cleared by Wait. This procedure is a
   --  convenience routine that can be used instead of an aggregate
   --  with only one event component.

private

   type Event_States is array (Event) of Boolean;

   type Retry_Entry_Id is mod 2;

   type Retry_Barriers is array (Retry_Entry_Id) of Boolean;

   protected type Manager is
      entry Wait
        (Any_Of_These : Event_List;
         Enabler      : out Event);
      procedure Signal (All_Of_These : Event_List);
   private
      Signaled      : Event_States := (others => False);
      Retry_Enabled : Retry_Barriers := (others => False);
      Active_Retry  : Retry_Entry_Id := Retry_Entry_Id'First;
      entry Retry (Retry_Entry_Id)
        (Any_Of_These : Event_List;
         Enabler      : out Event);
   end Manager;

end Event_Management;
