--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Search_Routines with SPARK_Mode is

   --------------
   -- Midpoint --
   --------------

   function Midpoint (Lower, Upper : Index) return Index is
     (Index'Val
        (Index'Pos (Lower) / 2 +
         Index'Pos (Upper) / 2 +
         (Index'Pos (Lower) rem 2 + Index'Pos (Upper) rem 2) / 2))
   with
     Pre    => Lower <= Upper,
     Post   => Midpoint'Result in Lower .. Upper,
     Global => null;
   --  Returns the index midway between Lower and Upper. Each operand is halved
   --  before summing, so the intermediate result cannot overflow.

   -------------------
   -- Binary_Search --
   -------------------

   procedure Binary_Search
     (Key      : Item;
      Table    : List;
      Position : out Index;
      Found    : out Boolean)
   is
      Lower : Index;
      Upper : Index;
      Ptr   : Index;
   begin
      Found := False;

      --  An empty table has no index in range; there is nothing to search.
      if Table'Length = 0 then
         Position := Index'First;
         return;
      end if;

      --  The table is not empty, so Table'First and Table'Last are in range.
      Position := Table'First;
      Lower    := Table'First;
      Upper    := Table'Last;
      Search : loop
         if Lower > Upper then
            return;
         end if;

         pragma Loop_Invariant (Lower in Table'Range);
         pragma Loop_Invariant (Upper in Table'Range);
         pragma Loop_Invariant (Lower <= Upper);
         pragma Loop_Invariant
           (for all K in Table'Range =>
              (if K < Lower or else K > Upper then not (Table (K) = Key)));
         pragma Loop_Variant (Decreases => Index'Pos (Upper) - Index'Pos (Lower));

         Ptr := Midpoint (Lower, Upper);

         if Table (Ptr) = Key then
            Found    := True;
            Position := Ptr;
            exit Search;
         elsif Table (Ptr) < Key then
            --  Every element at or below Ptr is <= Table (Ptr) < Key, so the
            --  key, if present, lies strictly above Ptr.
            if Ptr = Table'Last then
               pragma Assert (for all K in Table'Range => not (Table (K) = Key));
               return;
            end if;
            Lower := Index'Succ (Ptr);
         else -- must be greater than Key
            --  Every element at or above Ptr is >= Table (Ptr) > Key, so the
            --  key, if present, lies strictly below Ptr.
            if Ptr = Table'First then
               pragma Assert (for all K in Table'Range => not (Table (K) = Key));
               return;
            end if;
            Upper := Index'Pred (Ptr);
         end if;
      end loop Search;
   end Binary_Search;

   -------------------
   -- Linear_Search --
   -------------------

   procedure Linear_Search
     (Key      : Item;
      Table    : List;
      Position : out Index;
      Found    : out Boolean)
   is
   begin
      Found := False;

      --  An empty table has no index in range; there is nothing to search.
      if Table'Length = 0 then
         Position := Index'First;  -- aribtrary valid return value with Found = False
         return;
      end if;

      --  The table is not empty, so Table'First is in range.
      Position := Table'First;  -- default value if Found stays False

      Search : for Ptr in Table'Range loop
         if Table (Ptr) = Key then
            Found    := True;
            Position := Ptr;
            exit Search;
         elsif not (Table (Ptr) < Key) then -- no point in continuing
            --  Table (Ptr) > Key and every later element is >= Table (Ptr),
            --  so no element of Table can equal Key.
            pragma Assert (for all K in Table'Range => not (Table (K) = Key));
            exit Search;
         end if;

         pragma Loop_Invariant (for all K in Table'First .. Ptr => not (Table (K) = Key));
      end loop Search;
   end Linear_Search;

end Search_Routines;
