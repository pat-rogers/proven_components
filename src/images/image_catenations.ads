--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides functions for convenient output of value images and
--  strings. Specifically it provides two overloaded functions named "&", each
--  taking two arguments: one a value of the generic formal type, and the other
--  a value of standard String. The only difference between the two functions
--  is the order of the formal parameters. Both functions return a value of the
--  standard type String.
--
--  Those two functions make it convenient to write such expressions as, for
--  example, the following:
--
--     "X is " & X & " and Y is " & Y
--
--  where X and Y are objects of the type passed to the generic formal type in
--  an instantiation (and a use-clause on the instance is applied).
--
--  Arbitrary String values can be created without specifying the specific
--  function called within an expression. That flexibility is possible because
--  the two functions define both possible orders for the parameters, both
--  functions have the same operator name, and that name is the same as the
--  language-defined concatenation operator. The compiler will choose which
--  function is called (or reject it if ambiguous).
--
--  The result is a String value so you can use the result in any way allowed by
--  type String. For example:
--
--     X : constant Integer := 42;
--     Y : Integer := X + 1;
--     ...
--     Put_Line ("X is " & X & " and Y is " & Y);
--
--  will output "X is 42 and Y is 43" to Standard_Output.
--
--  Internally, the language-defined Image attribute is used to convert the
--  value to type String, which is then concatenated with the other parameter
--  (of type String) to create the result value. As of Ada 2022, the Image
--  attribute is no longer restricted to scalar types so Ada 2022 use is
--  suggested. For example:
--
--     type Ptr is access Integer;
--
--     package Ptr_Images is new Image_Catenations (Ptr);
--     use Ptr_Images;
--
--     P : Ptr;
--     ...
--     Put_Line ("P is initially " & P);
--     P := new Integer;
--     Put_Line ("P is now " & P);
--
--  will output "P is initially null"
--  followed by "P is now (access <some-address>)"
--  to Standard_Output, each on a separate line.
--
--  The generic formal type "Formal" is the type of the values to be passed to
--  'Image. Note that the generic formal type is declared in such a way as to
--  allow indefinite and limited types.
--
--  In practice, the type String should not be specified for Formal in an
--  instantiation. Although doing so would be legal, calls to the resulting "&"
--  functions would be ambiguous.
--
--  Note that Ada 2022 allows you to change how the Image attribute creates
--  values, via attribute Put_Image.
--
--  The generic formal Boolean object Trimming indicates whether the result
--  of Image is to be trimmed of leading and/or trailing blanks in the String
--  value returned. Blanks here means spaces and the other white space
--  characters, including the line terminators that the Image attribute emits
--  for composite types. The default value is True. Change that to False in an
--  instantiation if you already changed how the Image attribute works so
--  that leading blanks are not included.
--
--  The generic formal object Trim_Option, of type Ada.Strings.Trim_End,
--  indicates which ends of the result of Image should be trimmed. The default
--  is the left end. There's no effect if Trimming is set to False. Hence there's
--  no point to setting Trim_Option if Trimming is changed to False.
--
--  SPARK_Mode is not enabled because, as of the time of this writing (August
--  2026), attribute "Image" on non-scalar types is not yet supported by SPARK.

with Ada.Strings;

generic
   type Formal (<>) is limited private;
   Trimming    : Boolean := True;
   Trim_Option : Ada.Strings.Trim_End := Ada.Strings.Left;
package Image_Catenations is

   function "&" (Left : String;  Right : Formal) return String;
   --  Returns the String resulting from concatenating Left and the Image of
   --  Right, with the end(s) of Right'Image trimmed if Trimming is True.

   function "&" (Left : Formal;  Right : String) return String;
   --  Returns the String resulting from concatenating the Image of Left with
   --  Right, with the end(s) of Left'Image trimmed if Trimming is True.

end Image_Catenations;
