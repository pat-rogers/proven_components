--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

package body PI_Control with
  SPARK_Mode
is

   pragma Unevaluated_Use_Of_Old (Allow);

   Max_Real : constant Long_Real := Long_Real (Real'Last);
   Min_Real : constant Long_Real := Long_Real (Real'First);

   -----------------------
   -- Constrain_To_Real --
   -----------------------

   procedure Constrain_To_Real (Value : in out Long_Real) with
     Post => Value in Min_Real .. Max_Real,
     Inline;

   ---------------
   -- Constrain --
   ---------------

   procedure Constrain (Value : in out Real;  Limits : Bounds) with
     Post => Value in Limits.Min .. Limits.Max,
     Inline;

   ----------------------------
   -- Configure_Actual_Gains --
   ----------------------------

   procedure Configure_Actual_Gains
     (Specified_Kp : Real;
      Specified_Ki : Real;
      Period       : Positive_Milliseconds;
      Direction    : Controller_Directions;
      Actual_Kp    : out Real;
      Actual_Ki    : out Real);
   --  Sets the actual PID gain values based on the Specified values, the
   --  Period at which the controller will compute the output, and the
   --  Direction that the controller works.

   ---------------------------
   -- Configured_Controller --
   ---------------------------

   function Configured_Controller
     (Proportional_Gain : Real;
      Integral_Gain     : Real;
      Invocation_Period : Positive_Milliseconds;
      Output_Limits     : Bounds;
      Direction         : Controller_Directions := Direct)
   return PI_Controller
   is
   begin
      return Result : PI_Controller do
         Result.Enabled := False;
         Result.Period := Invocation_Period;
         Result.Output_Limits := Output_Limits;
         Result.Current_Direction := Direction;
         Result.Previous_PV := 0.0;
         Result.I_Term := 0.0;

         Result.Display_Kp := Proportional_Gain;
         Result.Display_Ki := Integral_Gain;

         Configure_Actual_Gains (Specified_Kp => Proportional_Gain,
                                 Specified_Ki => Integral_Gain,
                                 Period       => Invocation_Period,
                                 Direction    => Direction,
                                 Actual_Kp    => Result.Kp,
                                 Actual_Ki    => Result.Ki);
      end return;
   end Configured_Controller;

   --------------------
   -- Compute_Output --
   --------------------

   procedure Compute_Output
     (This             : in out PI_Controller;
      Process_Variable : Real;
      Setpoint         : Real;
      Control_Variable : in out Real)
   is
      Error      : Long_Real;
      New_Output : Long_Real;
   begin
      if not This.Enabled then
         return;
      end if;
      Error := Long_Real (Setpoint) - Long_Real (Process_Variable);
      This.I_Term := This.I_Term + (Long_Real (This.Ki) * Error);
      Constrain_To_Real (This.I_Term);
      Constrain (Real (This.I_Term), This.Output_Limits);
      New_Output := (Long_Real (This.Kp) * Error) + This.I_Term;
      Constrain_To_Real (New_Output);
      Constrain (Real (New_Output), This.Output_Limits);
      Control_Variable := Real (New_Output);
      This.Previous_PV := Process_Variable;
   end Compute_Output;

   ----------------------------
   -- Configure_Actual_Gains --
   ----------------------------

   procedure Configure_Actual_Gains
     (Specified_Kp : Real;
      Specified_Ki : Real;
      Period       : Positive_Milliseconds;
      Direction    : Controller_Directions;
      Actual_Kp    : out Real;
      Actual_Ki    : out Real)
   is
      Sample_Time_In_Sec : constant Long_Real := Long_Real (Period) / 1000.0;
      Temp  : Long_Real;
   begin
      Actual_Kp := Specified_Kp;

      --  This.Ki := Specified_Ki * Sample_Time_In_Sec;
      Temp := Long_Real (Specified_Ki) * Sample_Time_In_Sec;
      Constrain_To_Real (Temp);
      Actual_Ki := Real (Temp);

      if Direction = Reversed then
         Actual_Kp := -Actual_Kp;
         Actual_Ki := -Actual_Ki;
      end if;
   end Configure_Actual_Gains;

   ------------------------
   -- Reconfigure_Period --
   ------------------------

   procedure Reconfigure_Period
     (This       : in out PI_Controller;
      New_Period : Positive_Milliseconds)
   is
      Ratio : constant Real := Real (New_Period) / Real (This.Period);
      Temp  : Long_Real;
   begin
      --  This.Ki := This.Ki * Ratio;
      Temp := Long_Real (This.Ki) * Long_Real (Ratio);
      Constrain_To_Real (Temp);
      This.Ki := Real (Temp);

      This.Period := New_Period;
   end Reconfigure_Period;

   -------------------------------
   -- Reconfigure_Output_Limits --
   -------------------------------

   procedure Reconfigure_Output_Limits
     (This             : in out PI_Controller;
      Control_Variable : in out Real;
      New_Limits       : Bounds)
   is
   begin
      This.Output_Limits := New_Limits;
      if This.Enabled then
         Constrain (Control_Variable, This.Output_Limits);
         Constrain_To_Real (This.I_Term);
         Constrain (Real (This.I_Term), This.Output_Limits);
      end if;
   end Reconfigure_Output_Limits;

   ------------
   -- Enable --
   ------------

   procedure Enable
     (This             : in out PI_Controller;
      Process_Variable : Real;  -- the Process Variable
      Control_Variable : Real)  -- the Control/Manipulated Variable
   is
   begin
      if not This.Enabled then
         --  we are going from disabled to enabled so we ensure a
         --  "bumpless" mode change
         This.I_Term := Long_Real (Control_Variable);
         This.Previous_PV := Process_Variable;
         Constrain (Real (This.I_Term), This.Output_Limits);
      end if;
      This.Enabled := True;
   end Enable;

   -------------
   -- Disable --
   -------------

   procedure Disable (This : in out PI_Controller) is
   begin
      This.Enabled := False;
   end Disable;

   ---------------------------
   -- Reconfigure_Direction --
   ---------------------------

   procedure Reconfigure_Direction
     (This                : in out PI_Controller;
      Requested_Direction : Controller_Directions)
   is
   begin
      if This.Enabled and then This.Current_Direction /= Requested_Direction then
         This.Kp := -This.Kp;
         This.Ki := -This.Ki;
      end if;
      This.Current_Direction := Requested_Direction;
   end Reconfigure_Direction;

   ---------------------------------
   -- Reconfigure_Gain_Parameters --
   ---------------------------------

   procedure Reconfigure_Gain_Parameters
     (This              : in out PI_Controller;
      Proportional_Gain : Real;
      Integral_Gain     : Real)
   is
   begin
      This.Display_Kp := Proportional_Gain;
      This.Display_Ki := Integral_Gain;

      Configure_Actual_Gains (Specified_Kp => Proportional_Gain,
                              Specified_Ki => Integral_Gain,
                              Period       => This.Period,
                              Direction    => This.Current_Direction,
                              Actual_Kp    => This.Kp,
                              Actual_Ki    => This.Ki);
   end Reconfigure_Gain_Parameters;

   ---------------
   -- Constrain --
   ---------------

   procedure Constrain (Value : in out Real;  Limits : Bounds) is
   begin
      if Value > Limits.Max then
         Value := Limits.Max;
      elsif Value < Limits.Min then
         Value := Limits.Min;
      end if;
   end Constrain;

   -----------------------
   -- Constrain_To_Real --
   -----------------------

   procedure Constrain_To_Real (Value : in out Long_Real) is
   begin
      if Value > Max_Real then
         Value := Max_Real;
      elsif Value < Min_Real then
         Value := Min_Real;
      end if;
   end Constrain_To_Real;

end PI_Control;
