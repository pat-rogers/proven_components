--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Event_Management is

   ----------
   -- Wait --
   ----------

   procedure Wait
     (This         : in out Manager;
      Any_Of_These :        Event_List;
      Enabler      :    out Event)
   is
   begin
      This.Wait (Any_Of_These, Enabler);
   end Wait;

   ----------
   -- Wait --
   ----------

   procedure Wait
     (This     : in out Manager;
      This_One : Event)
   is
      Unused : Event;
   begin
      This.Wait (Event_List'(1 => This_One), Unused);
   end Wait;

   ------------
   -- Signal --
   ------------

   procedure Signal
     (This         : in out Manager;
      All_Of_These : Event_List)
   is
   begin
       --  Calling Manager.Signal has an effect even when the list
       --  is empty, albeit minor, so we don't call it in that case
      if All_Of_These'Length > 0 then
         This.Signal (All_Of_These);
      end if;
   end Signal;

   ------------
   -- Signal --
   ------------

   procedure Signal
     (This     : in out Manager;
      This_One : Event)
   is
   begin
      This.Signal (Event_List'(1 => This_One));
   end Signal;

   -------------
   -- Manager --
   -------------

   protected body Manager is

      procedure Check_Signaled
        (These   : Event_List;
         Enabler : out Event;
         Found   : out Boolean);

      ----------
      -- Wait --
      ----------

      entry Wait
        (Any_Of_These : Event_List;
         Enabler      : out Event)
      when
         True
      is
         Found_Signaled_Event : Boolean;
      begin
         Check_Signaled (Any_Of_These, Enabler, Found_Signaled_Event);
         if not Found_Signaled_Event then
            requeue Retry (Active_Retry) with abort;
         end if;
      end Wait;

      ------------
      -- Signal --
      ------------

      procedure Signal (All_Of_These : Event_List) is
      begin
         for C of All_Of_These loop
            Signaled (C) := True;
         end loop;
         Retry_Enabled (Active_Retry) := True;
      end Signal;

      -----------
      -- Retry --
      -----------

      entry Retry (for K in Retry_Entry_Id)
        (Any_Of_These : Event_List;
         Enabler      : out Event)
      when
         Retry_Enabled (K)
      is
         Found_Signaled_Event : Boolean;
      begin
         Check_Signaled (Any_Of_These, Enabler, Found_Signaled_Event);
         if Found_Signaled_Event then
            return;
         end if;
         if Retry (K)'Count = 0 then -- current caller is the last one
            --  switch to the other Retry family member for
            --  subsequent retries
            Retry_Enabled (K) := False;
            Active_Retry := Active_Retry + 1;
         end if;
         --  NB: K + 1 wraps around to the other family member
         requeue Retry (K + 1) with abort;
      end Retry;

      --------------------
      -- Check_Signaled --
      --------------------

      procedure Check_Signaled
        (These   : Event_List;
         Enabler : out Event;
         Found   : out Boolean)
      is
      begin
         for C of These loop
            if Signaled (C) then
               Signaled (C) := False;
               Enabler := C;
               Found := True;
               return;
            end if;
         end loop;
         Enabler := Event'First;  -- arbitrary, to prevent undefined value
         Found := False;
      end Check_Signaled;

   end Manager;

end Event_Management;
