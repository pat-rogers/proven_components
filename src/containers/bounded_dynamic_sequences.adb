--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Bounded_Dynamic_Sequences with SPARK_Mode is

   -----------
   -- Clear --
   -----------

   procedure Clear (This : out Sequence) is
   begin
      This.Current_Length := 0;
   end Clear;

   --------------
   -- Instance --
   --------------

   function Instance
     (Capacity : Natural_Index;
      Content  : List)
   return Sequence
   is
      Result : Sequence (Capacity);
   begin
      Result.Current_Length := Content'Length;
      Result.Content (1 .. Result.Current_Length) := Content_List (Content);
      pragma Assert (Value (Result) = Content);
      return Result;
   end Instance;

   --------------
   -- Instance --
   --------------

   function Instance
     (Content : List)
   return Sequence
   is
      Result : Sequence (Capacity => Content'Length);
   begin
      Result.Current_Length := Content'Length;
      Result.Content (1 .. Result.Current_Length) := Content_List (Content);
      return Result;
   end Instance;

   --------------
   -- Instance --
   --------------

   function Instance
     (Capacity : Natural_Index;
      Content  : Component)
   return Sequence
   is
      Result : Sequence (Capacity);
   begin
      Result.Current_Length := 1;
      Result.Content (1) := Content;
      return Result;
   end Instance;

   ----------
   -- Copy --
   ----------

   procedure Copy (Source : Sequence; To : in out Sequence) is
   begin
      To.Current_Length := Source.Current_Length;
      To.Content (1 .. To.Current_Length) := Source.Content (1 .. Source.Current_Length);
   end Copy;

   ----------
   -- Copy --
   ----------

   procedure Copy (Source : List; To : in out Sequence) is
   begin
      To.Current_Length := Source'Length;
      To.Content (1 .. To.Current_Length) := Content_List (Source);
   end Copy;

   ----------
   -- Copy --
   ----------

   procedure Copy (Source : Component; To : in out Sequence) is
   begin
      To.Content (1) := Source;
      To.Current_Length := 1;
   end Copy;

   ------------
   -- Append --
   ------------

   procedure Append (Tail : Sequence; To : in out Sequence) is
      New_Length : constant Natural_Index := Tail.Current_Length + To.Current_Length;
   begin
      To.Content (To.Current_Length + 1 .. New_Length) := Tail.Content (1 .. Tail.Current_Length);
      To.Current_Length := New_Length;
   end Append;

   ------------
   -- Append --
   ------------

   procedure Append (Tail : List; To : in out Sequence) is
      New_Length : constant Natural_Index := Tail'Length + To.Current_Length;
   begin
      To.Content (To.Current_Length + 1 .. New_Length) := Content_List (Tail);
      pragma Assert (To.Content (To.Current_Length + 1 .. New_Length) = Content_List (Tail));  -- needed for proof
      To.Current_Length := New_Length;
   end Append;

   ------------
   -- Append --
   ------------

   procedure Append (Tail : Component; To : in out Sequence) is
      New_Length : constant Index := 1 + To.Current_Length;
   begin
      To.Content (New_Length) := Tail;
      To.Current_Length := New_Length;
   end Append;

   -----------
   -- Amend --
   -----------

   procedure Amend (This : in out Sequence; By : Sequence; Start : Index) is
   begin
      Amend (This, Value (By), Start);
   end Amend;

   -----------
   -- Amend --
   -----------

   procedure Amend (This : in out Sequence; By : List; Start : Index) is
      Last : constant Index := Start + By'Length - 1;
   begin
      This.Content (Start .. Last) := Content_List (By);
      if Last > This.Current_Length then
         This.Current_Length := Last;
      end if;
   end Amend;

   -----------
   -- Amend --
   -----------

   procedure Amend (This : in out Sequence; By : Component; Start : Index) is
   begin
      This.Content (Start) := By;
   end Amend;

   --------------
   -- Location --
   --------------

   function Location (Fragment : List; Within : Sequence) return Natural_Index is
   begin
      --  We must check for the empty Fragment since that would be found, but
      --  we want to return zero (indicating not found) in that case. It would
      --  be found because on the first iteration with K = 1, the condition in
      --  the if-statement would be computing a null slice on the LHS of the
      --  comparison (ie, the range would be 1 .. 1+0-1), and that LHS would
      --  equal the RHS empty array fragment. We must also check for the
      --  fragment not being longer than the content of Within itself.
      if Fragment'Length in 1 .. Within.Current_Length then
         for K in 1 .. (Within.Current_Length - Fragment'Length + 1) loop
            if Contains_At (Within, K, Fragment) then
               return K;
            end if;
            pragma Loop_Invariant (for all J in 1 .. K => not Contains_At (Within, J, Fragment));
         end loop;
      end if;
      return 0;
   end Location;

   --------------
   -- Location --
   --------------

   function Location (Fragment : Component; Within : Sequence) return Natural_Index is
   begin
      for K in 1 .. Within.Current_Length loop
         if Within.Content (K) = Fragment then
            pragma Assert (Contains_At (Within, K, Fragment));
            return K;
         end if;
         pragma Loop_Invariant ((for all J in 1 .. K => Within.Content (J) /= Fragment));
      end loop;
      return 0;
   end Location;

   ----------------
   -- Normalized --
   ----------------

   function Normalized (L : List) return List is
    --  This is a function instead of a subtype because we need it in a
    --  postcondition as well as the "&" subprogram body, and we cannot
    --  define subtypes in postconditions.
      Result : constant List (1 .. L'Length) := L;
   begin
      return Result;
   end Normalized;

end Bounded_Dynamic_Sequences;
