--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body Kalman_Filters_Linear with SPARK_Mode is

   --  Contracted wrappers over the Ada.Numerics.Generic_Real_Arrays operations
   --  provided through VM_Ops. The wrapper bodies are SPARK_Mode => Off because
   --  the VM_Ops operations carry no contracts of their own; the postconditions
   --  here state the result dimensions the Ada reference manual guarantees, so
   --  callers can discharge the array length checks.

   function "*" (Left, Right : Real_Matrix) return Real_Matrix with
     Pre    => Left'Length (2) = Right'Length (1),
     Post   => "*"'Result'Length (1) = Left'Length (1) and then
               "*"'Result'Length (2) = Right'Length (2),
     Global => null,
     Inline;
   --  matrix product; result has Left's rows and Right's columns

   function "*" (Left : Real_Matrix; Right : Real_Vector) return Real_Vector with
     Pre    => Left'Length (2) = Right'Length,
     Post   => "*"'Result'Length = Left'Length (1),
     Global => null,
     Inline;
   --  matrix-by-vector product; result length is Left's row count

   function "+" (Left, Right : Real_Matrix) return Real_Matrix with
     Pre    => Left'Length (1) = Right'Length (1) and then
               Left'Length (2) = Right'Length (2),
     Post   => "+"'Result'Length (1) = Left'Length (1) and then
               "+"'Result'Length (2) = Left'Length (2),
     Global => null,
     Inline;
   --  matrix sum; result has the shared dimensions of the operands

   function "-" (Left, Right : Real_Matrix) return Real_Matrix with
     Pre    => Left'Length (1) = Right'Length (1) and then
               Left'Length (2) = Right'Length (2),
     Post   => "-"'Result'Length (1) = Left'Length (1) and then
               "-"'Result'Length (2) = Left'Length (2),
     Global => null,
     Inline;
   --  matrix difference; result has the shared dimensions of the operands

   function "+" (Left, Right : Real_Vector) return Real_Vector with
     Pre    => Left'Length = Right'Length,
     Post   => "+"'Result'Length = Left'Length,
     Global => null,
     Inline;
   --  vector sum; result has the shared length of the operands

   function "-" (Left, Right : Real_Vector) return Real_Vector with
     Pre    => Left'Length = Right'Length,
     Post   => "-"'Result'Length = Left'Length,
     Global => null,
     Inline;
   --  vector difference; result has the shared length of the operands

   function Transpose (X : Real_Matrix) return Real_Matrix with
     Post   => Transpose'Result'Length (1) = X'Length (2) and then
               Transpose'Result'Length (2) = X'Length (1),
     Global => null,
     Inline;
   --  matrix transpose; result has X's dimensions exchanged

   function Inverse (A : Real_Matrix) return Real_Matrix with
     Pre    => A'Length (1) = A'Length (2),
     Post   => Inverse'Result'Length (1) = A'Length (1) and then
               Inverse'Result'Length (2) = A'Length (2),
     Global => null,
     Inline;
   --  matrix inverse; result has the dimensions of the square input

   function Unit_Matrix
     (Order   : Positive;
      First_1 : Integer := 1;
      First_2 : Integer := 1) return Real_Matrix
   with
     Post   => Unit_Matrix'Result'Length (1) = Order and then
               Unit_Matrix'Result'Length (2) = Order,
     Global => null,
     Inline;
   --  identity matrix

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (This                        : out Kalman_Filter;
      Initial_State_Estimate      : Vector;
      State_Transition            : Square_Matrix;  -- A
      Control                     : Square_Matrix;  -- B
      Observation                 : Matrix;         -- H
      Initial_Covariance_Estimate : Square_Matrix;  -- P
      Estimated_Process_Error     : Square_Matrix;  -- Q
      Estimated_Measurement_Error : Square_Matrix)  -- R
   is
   begin
      This.Current_State := Initial_State_Estimate;
      This.A := State_Transition;
      This.B := Control;
      This.H := Observation;
      This.P := Initial_Covariance_Estimate;
      This.Q := Estimated_Process_Error;
      This.R := Estimated_Measurement_Error;
   end Initialize;

   ---------------------
   -- Update_Estimate --
   ---------------------

   procedure Update_Estimate
     (This           : in out Kalman_Filter;
      Control_Inputs : Vector;
      Observations   : Vector)
   is
      I  : constant Real_Matrix := Unit_Matrix (Order => This.Num_States);
      Ht : constant Real_Matrix := Transpose (This.H);
   begin
      This.Predicted_State := This.A * This.Current_State + This.B * Control_Inputs;
      This.Predicted_Probability := (This.A * This.P) * Transpose (This.A) + This.Q;
      This.Gain := (This.Predicted_Probability * Ht) * Inverse (This.H * This.Predicted_Probability * Ht + This.R);
      This.Current_State := This.Predicted_State + This.Gain * (Observations - This.H * This.Predicted_State);
      This.P := (I - This.Gain * This.H) * This.Predicted_Probability;
   end Update_Estimate;

   ---------------------
   -- Update_Estimate --
   ---------------------

   procedure Update_Estimate
     (This         : in out Kalman_Filter;
      Observations : Vector)
   is
      I  : constant Real_Matrix := Unit_Matrix (Order => This.Num_States);
      Ht : constant Real_Matrix := Transpose (This.H);
   begin
      This.Predicted_State := This.A * This.Current_State;
      This.Predicted_Probability := (This.A * This.P) * Transpose (This.A) + This.Q;
      This.Gain := (This.Predicted_Probability * Ht) * Inverse (This.H * This.Predicted_Probability * Ht + This.R);
      This.Current_State := This.Predicted_State + This.Gain * (Observations - This.H * This.Predicted_State);
      This.P := (I - This.Gain * This.H) * This.Predicted_Probability;
   end Update_Estimate;

   ---------------------
   -- Estimated_Value --
   ---------------------

   function Estimated_Value (This : Kalman_Filter) return Vector is
     (This.Current_State);

   --  Bodies of the VM_Ops wrappers declared above. Each is SPARK_Mode => Off:
   --  GNATprove uses the declared postconditions at the call sites and does not
   --  analyse these bodies, which simply delegate to the VM_Ops operations.

   ---------
   -- "*" --
   ---------

   function "*" (Left, Right : Real_Matrix) return Real_Matrix is
     (VM_Ops."*" (Left, Right))
   with SPARK_Mode => Off;

   ---------
   -- "*" --
   ---------

   function "*" (Left : Real_Matrix; Right : Real_Vector) return Real_Vector is
     (VM_Ops."*" (Left, Right))
   with SPARK_Mode => Off;

   ---------
   -- "+" --
   ---------

   function "+" (Left, Right : Real_Matrix) return Real_Matrix is
     (VM_Ops."+" (Left, Right))
   with SPARK_Mode => Off;

   ---------
   -- "-" --
   ---------

   function "-" (Left, Right : Real_Matrix) return Real_Matrix is
     (VM_Ops."-" (Left, Right))
   with SPARK_Mode => Off;

   ---------
   -- "+" --
   ---------

   function "+" (Left, Right : Real_Vector) return Real_Vector is
     (VM_Ops."+" (Left, Right))
   with SPARK_Mode => Off;

   ---------
   -- "-" --
   ---------

   function "-" (Left, Right : Real_Vector) return Real_Vector is
     (VM_Ops."-" (Left, Right))
   with SPARK_Mode => Off;

   ---------------
   -- Transpose --
   ---------------

   function Transpose (X : Real_Matrix) return Real_Matrix is
     (VM_Ops.Transpose (X))
   with SPARK_Mode => Off;

   -------------
   -- Inverse --
   -------------

   function Inverse (A : Real_Matrix) return Real_Matrix is
     (VM_Ops.Inverse (A))
   with SPARK_Mode => Off;

   -----------------
   -- Unit_Matrix --
   -----------------

   function Unit_Matrix
     (Order   : Positive;
      First_1 : Integer := 1;
      First_2 : Integer := 1)
   return Real_Matrix is
     (VM_Ops.Unit_Matrix (Order, First_1, First_2))
   with SPARK_Mode => Off;

end Kalman_Filters_Linear;
