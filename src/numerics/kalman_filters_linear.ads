--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This package defines an amateur-level Kalman abstract data
--  type for linear systems, suitable for hobbyists.

--  see http://greg.czerniak.info/guides/kalman1/

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

with Ada.Numerics.Generic_Real_Arrays;
--  Note that we're using this package's functions to manipulate the vector and
--  matrix values, rather than procedures (and their parameters), so there is
--  an inherent performance issue due to the copying that functions involve.
--  Would that we had user-defined build-in-place types... We're using the
--  functions because that is the closest correlation to the math, in order
--  to verify that the implementation is correct. Besides, the generic package
--  only provides the operations as functions anyway, so to use procedures we'd
--  need a different package.

generic
   type Real is digits <>;
   with package VM_Ops is new Ada.Numerics.Generic_Real_Arrays (Real); use VM_Ops;
package Kalman_Filters_Linear with
  SPARK_Mode,
  Always_Terminates
is

   type Kalman_Filter (Num_States, Num_Observables : Positive) is limited private with
     Relaxed_Initialization;

   subtype Vector is Real_Vector with
     Dynamic_Predicate => Vector'First > 0;  -- indexes are positive

   subtype Matrix is Real_Matrix with
     Dynamic_Predicate =>
        --  indexes are positive
        Matrix'First (1) > 0 and Matrix'Last (1) > 0 and
        Matrix'First (2) > 0 and Matrix'Last (2) > 0 and
        --  lengths are not null
        Matrix'First (1) <= Matrix'Last (1) and
        Matrix'First (2) <= Matrix'Last (2);

   subtype Square_Matrix is Matrix with
     Dynamic_Predicate => Square_Matrix'Length (1) = Square_Matrix'Length (2);

   procedure Initialize
     (This                        : out Kalman_Filter;
      Initial_State_Estimate      : Vector;
      State_Transition            : Square_Matrix;  -- A
      Control                     : Square_Matrix;  -- B
      Observation                 : Matrix;         -- H
      Initial_Covariance_Estimate : Square_Matrix;  -- P
      Estimated_Process_Error     : Square_Matrix;  -- Q
      Estimated_Measurement_Error : Square_Matrix)  -- R
   with
     Relaxed_Initialization => This,
     Pre => Initial_State_Estimate'Length = This.Num_States            and then
            Order (State_Transition) = This.Num_States                 and then
            Order (Control) = This.Num_States                          and then
            Order (Initial_Covariance_Estimate) = This.Num_States      and then
            Order (Estimated_Process_Error) = This.Num_States          and then
            Order (Estimated_Measurement_Error) = This.Num_Observables and then
            Has_Dimensions (Observation, This.Num_Observables, This.Num_States),
     Global => null;

   procedure Update_Estimate
     (This           : in out Kalman_Filter;
      Control_Inputs : Vector;
      Observations   : Vector)
   with
     Pre  => Observations'Length   = This.Num_Observables and then
             Control_Inputs'Length = This.Num_States,
     Post => Estimated_Value (This)'Length = This.Num_States,
     Global => null;
   --  Control_Inputs is any process inputs such as steering, etc., maybe none.
   --  Observations is a vector of current measurement (e.g., sensor) values.

   procedure Update_Estimate
     (This         : in out Kalman_Filter;
      Observations : Vector)
   with
     Pre  => Observations'Length = This.Num_Observables,
     Post => Estimated_Value (This)'Length = This.Num_States,
     Global => null;
   --  Called when there are no control inputs, instead of the other version.
   --  Observations is a vector of current measurement (e.g., sensor) values.

   function Estimated_Value (This : Kalman_Filter) return Vector with
     Inline,
     Post   => Estimated_Value'Result'Length = This.Num_States,
     Global => null;

   function Order (M : Square_Matrix) return Positive;

   function Has_Dimensions (M : Matrix; Length1, Length2 : Positive) return Boolean;

private

   type Kalman_Filter (Num_States, Num_Observables : Positive) is limited record
      Current_State   : Real_Vector (1 .. Num_States) := (others => 0.0);
      Predicted_State : Real_Vector (1 .. Num_States);

      --  The matrix components below are constrained to their (1 .. N, 1 .. N)
      --  bounds, so they are square and positive-indexed by construction; the
      --  Square_Matrix predicate would be redundant here and is therefore not
      --  applied. Square_Matrix is used on the operations' parameters instead.

      P : Real_Matrix (1 .. Num_States, 1 .. Num_States);
      --  prediction error covariance

      Q : Real_Matrix (1 .. Num_States, 1 .. Num_States);
      --  process noise covariance

      R : Real_Matrix (1 .. Num_Observables, 1 .. Num_Observables);
      --  measurement error covariance

      B : Real_Matrix (1 .. Num_States, 1 .. Num_States);
      --  the control matrix, in state space (maps a state-space control vector)

      Gain : Real_Matrix (1 .. Num_States, 1 .. Num_Observables);

      A : Real_Matrix (1 .. Num_States, 1 .. Num_States);
      --  state transition matrix

      H : Real_Matrix (1 .. Num_Observables, 1 .. Num_States);

      Predicted_Probability : Real_Matrix (1 .. Num_States, 1 .. Num_States);
   end record;

   function Order (M : Square_Matrix) return Positive is
     (M'Length (1));  --  arbitrary index, they are the same for a Square_Matrix

   function Has_Dimensions (M : Matrix; Length1, Length2 : Positive) return Boolean is
     (M'Length (1) = Length1 and then M'Length (2) = Length2);

end Kalman_Filters_Linear;
