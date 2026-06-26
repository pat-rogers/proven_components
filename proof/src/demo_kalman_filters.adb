--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  Runtime functionality test for Kalman_Filters_Linear, exercised through the
--  Float instance. Each case drives the filter and compares the resulting
--  state estimate against values computed by hand from the Kalman equations.
--
--  This is a test harness, not a proof target, so it is SPARK_Mode => Off.
--  Update_Estimate takes Filter as a plain "in out" parameter, so proving a
--  call site would oblige the caller to show the filter fully initialized
--  first -- a property of the filter's use, not of this functional test.

with Ada.Text_IO; use Ada.Text_IO;
with Kalman_Filters_Instance;

procedure Demo_Kalman_Filters with SPARK_Mode => Off is

   use Kalman_Filters_Instance.Float_Kalman_Filters;
   use Kalman_Filters_Instance.Float_Real_Arrays;

   subtype Vector_2 is Real_Vector (1 .. 2);
   subtype Matrix_2 is Real_Matrix (1 .. 2, 1 .. 2);

   Tolerance : constant Float := 1.0E-5;
   --  Float carries roughly seven significant digits; each test value is
   --  reached in a handful of operations, so results stay within this margin.

   Failures : Natural := 0;

   -----------
   -- Check --
   -----------

   procedure Check (Label : String; Computed, Expected : Float) is
   begin
      if abs (Computed - Expected) <= Tolerance then
         Put_Line ("  PASS  " & Label & " =" & Computed'Image);
      else
         Failures := Failures + 1;
         Put_Line ("  FAIL  " & Label & " =" & Computed'Image &
                   "  (expected" & Expected'Image & ")");
      end if;
   end Check;

   ----------------------
   -- Scalar_No_Control --
   ----------------------

   --  Scalar (one state, one observable) filter with no control input. With
   --  A = H = 1, Q = 0, R = 1, x0 = 0 and P0 = 1, a measurement z folds in as
   --  K = P / (P + 1),  x := x + K * (z - x),  P := (1 - K) * P.

   procedure Scalar_No_Control is
      Filter : Kalman_Filter (Num_States => 1, Num_Observables => 1);
   begin
      Put_Line ("Scalar filter, no control input:");
      Initialize
        (Filter,
         Initial_State_Estimate      => (1 => 0.0),
         State_Transition            => (1 => (1 => 1.0)),
         Control                     => (1 => (1 => 1.0)),
         Observation                 => (1 => (1 => 1.0)),
         Initial_Covariance_Estimate => (1 => (1 => 1.0)),
         Estimated_Process_Error     => (1 => (1 => 0.0)),
         Estimated_Measurement_Error => (1 => (1 => 1.0)));

      --  z = 2: K = 1 / (1 + 1) = 0.5,  x = 0 + 0.5 * (2 - 0) = 1.0,  P = 0.5
      Update_Estimate (Filter, Observations => (1 => 2.0));
      Check ("estimate after z = 2.0 (1st update)", Estimated_Value (Filter) (1), 1.0);

      --  z = 2 again: P_prior = 0.5, K = 0.5 / 1.5 = 1/3, x = 1 + (1/3)(2 - 1)
      Update_Estimate (Filter, Observations => (1 => 2.0));
      Check ("estimate after z = 2.0 (2nd update)", Estimated_Value (Filter) (1), 4.0 / 3.0);
   end Scalar_No_Control;

   ------------------------
   -- Scalar_With_Control --
   ------------------------

   --  Scalar filter with a control input. x_prior = A*x + B*u = 0 + 1 = 1,
   --  then z = 2 folds in: K = 0.5, x = 1 + 0.5 * (2 - 1) = 1.5.

   procedure Scalar_With_Control is
      Filter : Kalman_Filter (Num_States => 1, Num_Observables => 1);
   begin
      Put_Line ("Scalar filter, with control input:");
      Initialize
        (Filter,
         Initial_State_Estimate      => (1 => 0.0),
         State_Transition            => (1 => (1 => 1.0)),
         Control                     => (1 => (1 => 1.0)),
         Observation                 => (1 => (1 => 1.0)),
         Initial_Covariance_Estimate => (1 => (1 => 1.0)),
         Estimated_Process_Error     => (1 => (1 => 0.0)),
         Estimated_Measurement_Error => (1 => (1 => 1.0)));

      Update_Estimate (Filter, Control_Inputs => (1 => 1.0), Observations => (1 => 2.0));
      Check ("estimate after u = 1.0, z = 2.0", Estimated_Value (Filter) (1), 1.5);
   end Scalar_With_Control;

   ------------------------
   -- Two_State_Diagonal --
   ------------------------

   --  Two independent states, no control. A = H = P0 = R = identity, Q = 0,
   --  so each state behaves as the scalar case: z = (2, 4) -> estimate (1, 2).

   procedure Two_State_Diagonal is
      Identity : constant Matrix_2 := ((1.0, 0.0), (0.0, 1.0));
      Zero     : constant Matrix_2 := ((0.0, 0.0), (0.0, 0.0));
      Filter   : Kalman_Filter (Num_States => 2, Num_Observables => 2);
   begin
      Put_Line ("Two-state diagonal filter, no control input:");
      Initialize
        (Filter,
         Initial_State_Estimate      => Vector_2'(0.0, 0.0),
         State_Transition            => Identity,
         Control                     => Identity,
         Observation                 => Identity,
         Initial_Covariance_Estimate => Identity,
         Estimated_Process_Error     => Zero,
         Estimated_Measurement_Error => Identity);

      Update_Estimate (Filter, Observations => Vector_2'(2.0, 4.0));
      Check ("state 1 after z = (2.0, 4.0)", Estimated_Value (Filter) (1), 1.0);
      Check ("state 2 after z = (2.0, 4.0)", Estimated_Value (Filter) (2), 2.0);
   end Two_State_Diagonal;

begin
   Put_Line ("=== Kalman_Filters_Linear functionality test ===");
   New_Line;
   Scalar_No_Control;
   New_Line;
   Scalar_With_Control;
   New_Line;
   Two_State_Diagonal;
   New_Line;

   if Failures = 0 then
      Put_Line ("All checks passed.");
   else
      Put_Line (Failures'Image & " check(s) FAILED.");
   end if;
end Demo_Kalman_Filters;
