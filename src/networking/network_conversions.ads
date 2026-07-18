--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package provides standard network::host value conversions for 16- and
--  32-bit unsigned types

with Interfaces; use Interfaces;

package Network_Conversions with SPARK_Mode is
   pragma Pure;

   function To_Network (Value : Unsigned_32) return Unsigned_32 with Inline;
   function To_Network (Value : Unsigned_16) return Unsigned_16 with Inline;

   function To_Host (Value : Unsigned_32) return Unsigned_32 with Inline;
   function To_Host (Value : Unsigned_16) return Unsigned_16 with Inline;

end Network_Conversions;
