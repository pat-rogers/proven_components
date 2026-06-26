--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

with Character_Sets; use Character_Sets;
with Ada.Text_IO;    use Ada.Text_IO;

procedure Demo_Sets with SPARK_Mode is

   Vowels : constant Set := New_Set (Content => ('a', 'e', 'i', 'o', 'u'));

   S : Set;

   procedure Print (Prompt : String;  This : Set) is
   begin
      Put (Prompt & """");
      for C : Character of This loop
         Put (C);
      end loop;
      Put ("""");
   end Print;

begin
   Put_Line ("Cardinality of Null_Set is" & Cardinality (Null_Set)'Image);
   pragma Assert (Cardinality (Null_Set) = 0);

   Print ("Vowels contains ", Vowels);
   New_Line;
   Put_Line ("Cardinality of Vowels is" & Cardinality (Vowels)'Image);
   pragma Assert (Cardinality (Vowels) = 5);

   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   pragma Assert (Empty (S));
   pragma Assert (Cardinality (S) = 0); -- Cardinality not yet proven on this operation

   Put_Line ("Setting S to new set containing one element 'e'");
   S := New_Set ('e');
   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   pragma Assert (Cardinality (S) = 1);

   Put_Line ("Setting S to new set containing elements 'a' and 'b'");
   S := New_Set (Content => ('a', 'b'));
   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   pragma Assert (Cardinality (S) = 2);

   Put_Line ("Adding new member 'e' to S");
   S := S + 'e';
   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   pragma Assert (Cardinality (S) = 3);

   Put_Line ("Removing member 'a' from S");
   S := S - 'a';
   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   pragma Assert (Cardinality (S) = 2);

   Put_Line ("Forming intersection of S and Vowels");
   S := S and Vowels;
   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   --  pragma Assert (Cardinality (S) = 1); -- Cardinality not yet proven on this operation

   Put_Line ("Forming union of S and Vowels");
   S := S or Vowels;
   Print ("S contains ", S);
   New_Line;
   Put_Line ("Cardinality of S is" & Cardinality (S)'Image);
   --  pragma Assert (Cardinality (S) = 5); -- Cardinality not yet proven on this operation

   Put_Line ("Done");
end Demo_Sets;

