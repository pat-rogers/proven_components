--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Sequential_Bounded_Queues with SPARK_Mode is

   ------------
   -- Insert --
   ------------

   procedure Insert (This : in out Queue; Item : Element) is
   begin
      --  We haven't incremented Length yet, so if Full returns true the
      --  buffer was already full before this call to Insert.
      if Full (This) then
         --  This new element goes at the "end" of the buffer content, which
         --  is ordered oldest to newest. The oldest is at First, therefore
         --  the new element, Item, overwrites the value at First. We then
         --  make that the last element in the buffer (the newest inserted)
         --  by incrementing First without changing Length.
         This.Content (This.First) := Item;
         This.First := Next_Index (This, Offset => 1);
      else  -- not full on entry
         This.Content (Next_Index (This, This.Length)) := Item;
         This.Length := This.Length + 1;
      end if;
   end Insert;

   -----------------------
   -- Insert_Preserving --
   -----------------------

   procedure Insert_Preserving (This : in out Queue; Item : Element) is
   begin
      This.Content (Next_Index (This, This.Length)) := Item;
      This.Length := This.Length + 1;
   end Insert_Preserving;

   ------------
   -- Remove --
   ------------

   procedure Remove (This : in out Queue; Item : out Element) is
   begin
      Item := This.Content (This.First);
      This.Length := This.Length - 1;
      This.First := Next_Index (This, Offset => 1);
   end Remove;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : out Queue) is
   begin
      This.First := This.Content'First;
      This.Length := 0;
   end Reset;

   ------------
   -- Delete --
   ------------

   procedure Delete (This : in out Queue;  Number_To_Delete : Positive_Element_Count) is
      Actual_Deletions : constant Base_Integer := Base_Integer'Min (Number_To_Delete, This.Length);
   begin
      This.First := Next_Index (This, Actual_Deletions);
      This.Length := This.Length - Actual_Deletions;
   end Delete;

   ----------
   -- Copy --
   ----------

   procedure Copy (Source : Queue; Target : in out Queue) is
   begin
      Target.Length := Source.Length;
      Target.First := Target.Content'First;

      for J in 1 .. Source.Length loop
         Target.Content (J) := Source.Content (Next_Index (Source, J - 1));

         pragma Loop_Invariant
           (for all K in 1 .. J =>
              Target.Content (Next_Index (Target, K - 1))'Initialized);

         pragma Loop_Invariant
           (for all K in 1 .. J =>
              Target.Content (K) = Source.Content (Next_Index (Source, K - 1)));
      end loop;
   end Copy;

   -----------
   -- Model --
   -----------

   function Model (This : Queue) return Queue_Model with
     Refined_Post =>
        Model'Result'First = 1            and then
        Model'Result'Length = This.Length and then
        (for all J in 1 .. This.Length =>
            Model'Result (J) = This.Content (Next_Index (This, Offset => J - 1)) and then
            Model'Result (J)'Initialized)
   is
      Result : Queue_Model (1 .. This.Length);
   begin
      for K in Result'First .. This.Length loop
         Result (K) := This.Content (Next_Index (This, Offset => K - 1));

         pragma Loop_Invariant
           (for all J in 1 .. K =>
               Result (J) = This.Content (Next_Index (This, Offset => J - 1)));

         pragma Loop_Invariant
           (for all J in 1 .. K => Result (J)'Initialized);
      end loop;
      return Result;
   end Model;

   --  Iterator routines  -------------------------------------------------------------------

   ----------------------
   -- First_Iter_Index --
   ----------------------

   function First_Iter_Index (Unused : Queue) return Positive_Element_Count is
     (1);
   --  Position represents an iteration count (1 .. Length), not a buffer
   --  index. Starting at 1 means Iter_Has_Element returns True iff the queue
   --  is non-empty; Iter_Value then maps Position to the actual buffer index.

   ---------------------
   -- Next_Iter_Index --
   ---------------------

   function Next_Iter_Index
     (Unused   : Queue;
      Position : Positive_Element_Count)
      return Positive_Element_Count
   is
     (if Position = Positive_Element_Count'Last then 1 else Position + 1);
   --  Position must not be limited only to values for which Iter_has_Element
   --  could return True, otherwise iteration might never stop. For example,
   --  if the buffer is full and First is Content'First and this function only
   --  iterated over Content'First through Capacity, the iteration would never
   --  terminate. Therefore we just increment the incoming value, wrapping
   --  around 'Last as need be, and letting Iter_Has_Element identify when
   --  to stop.

   ----------------------
   -- Iter_Has_Element --
   ----------------------

   function Iter_Has_Element
     (This     : Queue;
      Position : Positive_Element_Count)
   return Boolean is
     (Position <= This.Length);
   --  Position is an iteration count starting at 1 (per First_Iter_Index) and
   --  incremented by Next_Iter_Index. We stop when Position exceeds the number
   --  of contained elements. For an empty queue (Length = 0) this returns
   --  False immediately since Position starts at 1 and 1 <= 0 is False.

   ----------------
   -- Iter_Value --
   ----------------

   function Iter_Value
     (This     : Queue;
      Position : Positive_Element_Count)
   return Element
   is
      --  Position is the 1-based iteration count. The Position-th contained
      --  element lives at Next_Index (This, Offset => Position - 1), which
      --  handles wrap-around within the Content array. The Type_Invariant
      --  guarantees that every component within the contained slice is
      --  initialized, so the read below is provably safe.
      Mapped_Pos : constant Positive_Element_Count := Next_Index (This, Offset => Position - 1);
   begin
      return This.Content (Mapped_Pos);
   end Iter_Value;

end Sequential_Bounded_Queues;
