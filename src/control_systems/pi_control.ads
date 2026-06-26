--
--  Copyright (C) 2026 Patrick Rogers
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Author: Patrick Rogers, progers@classwide.com

--  This generic package is based on the Arduino PID library, version 1.1.1,
--  available here: https://playground.arduino.cc/Code/PIDLibrary
--
--  Note that this is a PI controller, not a PID controller.
--
--  The primary difference between this implementation and the Arduino version
--  is that the controller object does not compute the next time to execute.
--  The computation update procedure must be called at the rate specified to
--  the Configured_Controller routine. In addition, the PID object does not
--  retain pointers to the input, setpoint, and output objects (for the sake
--  of SPARK compatibility).
--
--  The type PI_Controller is the primary abstraction. As part of the
--  declaration of an object of this type the compiler will require a call
--  to the function Configured_Controller.
--
--        Controller : PI_Controller := Configured_Controller (...);
--
--  For a great explanation of the implementation, step-by-step, see
--  http://brettbeauregard.com/blog/2011/04/improving-the-beginners-pid-introduction/
--
--  see https://os.mbed.com/users/aberk/code/PID/file/6e12a3e5af19/PID.h/
--  for a version using percentages

--  See the "Controlling Runtime Checks" section of README.md regarding whether
--  to disable preconditions. In general you should not disable precondition
--  checks at runtime (if present).

generic
   type Real is digits <>;
   --  The type used for inputs, outputs, gain parameters, etc.

   type Long_Real is digits <>;
   --  Type Long_Real is used internally, within the PID controller
   --  implementation, to avoid overflow. The actual parameter must have at
   --  least twice the number of digits as the actual for Real, otherwise the
   --  compiler will reject the instantiation.
package PI_Control with
  SPARK_Mode,
  Always_Terminates
is

   pragma Compile_Time_Error
     (Long_Real'Digits < 2 * Real'Digits,
      "Second generic actual type must have at least twice " &
      "the digits of first generic actual type.");

   pragma Unevaluated_Use_Of_Old (Allow);

   type PI_Controller (<>) is tagged limited private;

   type Bounds is record
      Min, Max : Real;
   end record with
     Predicate => Min < Max;
   --  A type used to express the minimum and maximum bounds for constraining
   --  output values at runtime

   type Controller_Directions is (Direct, Reversed);
   --  In a Direct acting process +output leads to +input, whereas in a
   --  Reversed process +output leads to -input.

   type Millisecond_Units is mod 2**32;

   subtype Positive_Milliseconds is
     Millisecond_Units range 1 .. Millisecond_Units'Last;
   --  The subtype used for expressing the iterative period at which the output
   --  computation procedure will be called

   function Configured_Controller
     (Proportional_Gain : Real;
      Integral_Gain     : Real;
      Invocation_Period : Positive_Milliseconds;
      Output_Limits     : Bounds;
      Direction         : Controller_Directions := Direct)
   return PI_Controller
   with
     Global => null,
     Post'Class =>
        not Enabled (Configured_Controller'Result)                           and then
        Current_Direction (Configured_Controller'Result) = Direction         and then
        Current_Period (Configured_Controller'Result) = Invocation_Period    and then
        Current_Output_Limits (Configured_Controller'Result) = Output_Limits and then
        Specified_Kp (Configured_Controller'Result) = Proportional_Gain      and then
        Specified_Ki (Configured_Controller'Result) = Integral_Gain;
   --  Configures the initial values. Must be called as part of a
   --  PI_Controller object declaration (a compile-time requirement); after
   --  that some settings can be individually altered via dedicated procedures.
   --
   --  Note that Invocation_Period is the periodic interval at which procedure
   --  Compute_Output is called by the application, and must match reality!
   --
   --  Note that Proportional_Gain is applied to the error, in other words it
   --  is Setpoint - Process_Variable, not the change in input values

   procedure Enable
     (This             : in out PI_Controller;
      Process_Variable : Real;  -- current input value from the process
      Control_Variable : Real)  -- current output value
   with
     Global => null,
     Post'Class => Enabled (This) and
                   Current_Output_Limits (This) = Current_Output_Limits (This)'Old;
   --  In this mode calls to Compute_Output update the output argument. The
   --  Process_Variable and Control_Variable values are used for "bumpless"
   --  transitions from the Disabled to Enabled state.

   procedure Disable (This : in out PI_Controller) with
     Global => null,
     Post'Class => not Enabled (This);
   --  In this mode calls to Compute_Output will do nothing.

   procedure Compute_Output
     (This             : in out PI_Controller;
      Process_Variable : Real;         -- the input, Measured Value/Variable
      Setpoint         : Real;
      Control_Variable : in out Real)  -- the output, Manipulated Variable
   with
     Global => null,
     Post'Class => Current_Output_Limits (This) = Current_Output_Limits (This)'Old and then
                   (if Enabled (This)'Old
                      then Within_Limits (Control_Variable, Current_Output_Limits (This))
                      else Control_Variable = Control_Variable'Old);
   --  When Enabled, computes the new value for the parameter passed to
   --  Control_Variable, based on the values of Process_Variable and Setpoint.
   --  Can be called when not Enabled but in that case will do nothing.
   --
   --  When controlling an actual physical plant, must be called at the
   --  Current_Period specified by the value passed to Configure or to
   --  Reconfigure_Period. This requirement exists because the elapsed time
   --  per call is part of the output calculations.

   procedure Reconfigure_Output_Limits
     (This             : in out PI_Controller;
      Control_Variable : in out Real;
      New_Limits       : Bounds)
   with
     Global => null,
     Post'Class => Current_Output_Limits (This) = New_Limits and then
                   Enabled (This) = Enabled (This)'Old       and then
                   (if Enabled (This)'Old
                      then Within_Limits (Control_Variable, Current_Output_Limits (This))
                      else Control_Variable = Control_Variable'Old);
   --  Change the min and max output limits.

   procedure Reconfigure_Period
     (This       : in out PI_Controller;
      New_Period : Positive_Milliseconds)
   with
     Global => null,
     Post'Class => Current_Period (This) = New_Period;
   --  Change the period at which Compute_Output will be called, and dependent
   --  internal parameters.

   procedure Reconfigure_Direction
     (This                : in out PI_Controller;
      Requested_Direction : Controller_Directions)
   with
     Global => null,
     Post'Class => Current_Direction (This) = Requested_Direction;
   --  Change the current direction of the process to which the controller is
   --  connected.

   procedure Reconfigure_Gain_Parameters
     (This              : in out PI_Controller;
      Proportional_Gain : Real;
      Integral_Gain     : Real)
   with
     Global => null,
     Post'Class => Specified_Kp (This) = Proportional_Gain and then
                   Specified_Ki (This) = Integral_Gain;
   --  Allows these parameters to be changed on the fly. This facility is
   --  useful when we want the controller to be aggressive at some times and
   --  conservative at others. For example, we can set the controller to use
   --  conservative tuning parameters when near the setpoint and more aggressive
   --  tuning parameters when farther away.

   function Enabled (This : PI_Controller) return Boolean with
     Global => null;

   function Current_Output_Limits (This : PI_Controller) return Bounds with
     Global => null;

   function Current_Direction (This : PI_Controller) return Controller_Directions with
     Global => null;

   function Current_Period (This : PI_Controller) return Positive_Milliseconds with
     Global => null;

   --  These functions return the tuning parameters as specified by the client.
   --  The parameters actually used are based on those specified values but are
   --  not the same actual values so we provide a way to get those originally
   --  specified.

   function Specified_Kp (This : PI_Controller) return Real with
     Global => null;

   function Specified_Ki (This : PI_Controller) return Real with
     Global => null;

   function Within_Limits (Value : Real; Limits : Bounds) return Boolean with
     Ghost,
     Inline;
   --  util function used in postconditions

private

   type PI_Controller is tagged limited record
      --  the unaltered tuning parameters specified by the client
      Display_Kp        : Real;
      Display_Ki        : Real;

      --  the actual tuning parameters applied
      Kp                : Real;
      Ki                : Real;

      Previous_PV       : Real;
      I_Term            : Long_Real;
      Current_Direction : Controller_Directions;
      Period            : Positive_Milliseconds;
      Output_Limits     : Bounds;
      Enabled           : Boolean;
   end record;

   -------------
   -- Enabled --
   -------------

   function Enabled (This : PI_Controller) return Boolean is
     (This.Enabled);

   -------------------
   -- Within_Limits --
   -------------------

   function Within_Limits (Value : Real; Limits : Bounds) return Boolean is
     (Value in Limits.Min .. Limits.Max);

   -----------------------
   -- Current_Direction --
   -----------------------

   function Current_Direction (This : PI_Controller) return Controller_Directions is
     (This.Current_Direction);

   ---------------------------
   -- Current_Output_Limits --
   ---------------------------

   function Current_Output_Limits (This : PI_Controller) return Bounds is
     (This.Output_Limits);

   --------------------
   -- Current_Period --
   --------------------

   function Current_Period (This : PI_Controller) return Positive_Milliseconds is
     (This.Period);

   ------------------
   -- Specified_Kp --
   ------------------


   function Specified_Kp (This : PI_Controller) return Real is
     (This.Display_Kp);

   ------------------
   -- Specified_Ki --
   ------------------

   function Specified_Ki (This : PI_Controller) return Real is
     (This.Display_Ki);

end PI_Control;
