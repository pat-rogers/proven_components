--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  The generic package provides classic search routines for sorted lists.

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

--  However, for this specific generic package, enabling preconditions is
--  unrealistic because it will be too expensive for most cases and will
--  not cause an exception if not checked. Therefore, we make the function
--  Sorted_Ascending be a ghost routine and declare it here in this generic
--  package so we can use it as such. This usage is different from the sorting
--  facilities, for example, because there Sorted_Ascending is called in the
--  postconditions instead of the preconditions, and a sorting demo might want
--  to call it in a pragma Assert.

generic
   type Item is limited private;
   type Index is (<>);
   type List is array (Index range <>) of Item;
   with function "<" (Left, Right : Item) return Boolean is <>;
   with function "=" (Left, Right : Item) return Boolean is <>;
package Search_Routines with
  SPARK_Mode,
  Always_Terminates
is

   procedure Binary_Search
     (Key      : Item;
      Table    : List;
      Position : out Index;
      Found    : out Boolean)
   with
     Pre  => Sorted_Ascending (Table),
     Post => Found = (for some K in Table'Range => Table (K) = Key) and then
             (if Found then
                Position in Table'Range and then
                Table (Position) = Key);

   procedure Linear_Search
     (Key      : Item;
      Table    : List;
      Position : out Index;
      Found    : out Boolean)
   with
     Pre  => Sorted_Ascending (Table),
     Post => Found = (for some K in Table'Range => Table (K) = Key) and then
             (if Found then
                Position in Table'Range and then
                Table (Position) = Key  and then
                (for all K in Table'Range =>
                   (if K < Position then not (Table (K) = Key))));

   function Sorted_Ascending (This : List) return Boolean is
     (for all I in This'Range =>
        (for all J in This'Range =>
           (if I < J then not (This (J) < This (I)))))
   with Ghost;
   --  True when no element of This is strictly less than an element that
   --  precedes it, i.e. This is in ascending order.

end Search_Routines;
