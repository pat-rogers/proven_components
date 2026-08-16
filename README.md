# Proven Components

This project contains general purpose, reusable components written in SPARK or Ada. They are intended for both native and embedded applications.

The units are selected from a set of Ada components that I have created and used over the past few decades of Ada development (since 1980). I recently revised many of them for the sake of formal verification using SPARK. Hence they are both proven useful and proven formally as well.

Sample contents:

- Sequential Bounded Buffers
- Sequential Bounded Stacks (i.e., not thread-safe)
- ...
- Protected types providing synchronization protocols
- PI and PID Controls
- Image functions for floating- and fixed-point types, in standard (i.e., not scientific) notation
- Gaussian, Categorical, and Scaled Uniform Random Number Generators
- Recursive Moving Average (RMA) filters for signal processing
- Sorting and Searching routines
- ...

All possible components have been verified to their highest possible level, usually to the Gold or Platinum level, i.e., the highest SPARK levels. All proven components are proven at least to the Silver level. 

Some components are not in the SPARK subset. These components are not proven.

Because each proven component is at least at the Silver level, these components are proven to have no run-time errors. These errors include:

- Array index errors
- Numeric range errors
- Numeric overflow errors and underflow errors
- Reads of variables that have no value
- Access to global data when you do not want it
- Other errors.

For full data about the proof levels and their results, refer to the SPARK User Guide. The applicable section is at this URL:
https://docs.adacore.com/spark2014-docs/html/ug/en/usage_scenarios.html#levels-of-spark-use

The subsection for the Silver level is here:
https://docs.adacore.com/spark2014-docs/html/ug/en/usage_scenarios.html#silver-level-absence-of-run-time-errors-aorte

## The Components

All the components are in the src/ directory tree. Subdirectories group them by function.

### Unit Names

The names of the generic packages, and thus the names of their files, usually show specified properties of the components. For example:

- Whether objects of the type are thread-safe
- Whether objects of the type are bounded or unbounded in their memory usage
- The general abstraction.

The unit name contains "sequential" or "concurrent" to show whether the component is thread-safe. It contains "bounded" or "unbounded" to show the memory usage.

For example, the file "sequential_bounded_buffers.ads" contains the generic package declaration for a buffer ADT. Objects of this type have no protection from concurrent access. They are also bounded in their memory usage.

The names can contain other indicators when necessary. For example, a generic package name can include "discrete". This shows that the component accepts only discrete types for the generic formal type.

### Proof Utility Components

Some of the components use "utility" components that make proof easier. These utility components are generics that you can use again. Thus you can use them in new components where verification is necessary. This includes components that clients write. These generic packages are in the "src/proof_utils/" subdirectory, below the source directory that contains the primary components.

They are part of the project of "proven_components.gpr". They are not part of the different project that starts the provers on test instantiations.

For example, a usual implementation idiom uses an array of Boolean components. Each Boolean shows something about the value that agrees with the index of that array component. A specified example is the "Set" ADT, which contains member values of some discrete type. The discrete "member" type indexes the Boolean array. Thus each component value shows whether the applicable member index value is in the set, or is not in the set.

One of the Set operations shows how many members a Set object holds at that time. This quantity is the total number of Boolean components that are True. Other operations add or remove one member of a given set, and increase or decrease that total. Proof of the relation between changes to one array component and the total uses induction, which is not possible without lemmas.

Thus the utility generic package Boolean_Array_Extent supplies a function Extent. This function shows the number of True components. The package also supplies lemma procedures that make proof of the increase operations and the decrease operations easier. New primary components can use this generic package again. New components that users write can use it too.

## Using the Library

To make the components available to your project, specify the GNAT project file "proven_components.gpr" in a with-clause in that project. Most of the components are generic units. Thus clients must instantiate them.

"proven_components.gpr" is the only project file in the project root. It is also the only project file for clients.

### Client Compilation and Build

When you build a client project that has a with-clause for "proven_components.gpr", the GNAT builder builds these components automatically. The object files of the components go in an object directory that is local to the Proven_Components project. They do not go in the object directories of client projects. That directory is "obj/Full", "obj/Embedded", or "obj/Light", which agrees with the source "profile." Refer to the next section for the source profile.

When the builder builds the components, it applies the switches in the "proven_components.gpr" project file. These switches include optimization at level O2. They also include the compiler switches that are necessary to remove code and data that is not used, automatically at link-time.

Some of the components use Ada 2022 syntax. Thus the builder always applies the corresponding switch when it builds the components.

### Selecting the Source Profile

The crate declares a configuration variable "Profile". This variable is an enumeration with the values `Full`, `Embedded`, and `Light`. It selects the source directories that "proven_components.gpr" compiles:

- `Full` compiles all the source below "src/".
- `Embedded` compiles the same set, but not "src/concurrency/". 
- `Light` compiles the `Embedded` set, but not the components that require library units which a runtime below the embedded level does not supply.

The variable is necessary because the GNAT builder compiles each source in the source directories of a project. The builder does this whether the client instantiates the units in them or not. The units in "src/concurrency/" use tasking constructs that the restricted tasking runtimes do not supply. Thus a client that builds against a Ravenscar runtime or a Jorvik runtime cannot compile them, as on a bare-board embedded target. As a result, that client cannot build the library, although it does not reference those units.

If you select `Embedded`, the builder does not build those units. This causes no problem, because a client on such a runtime could not use them.

The `Light` profile applies to a client that builds against a light runtime or a light-tasking runtime. Such a runtime does not supply Ada.Calendar, Ada.Streams, Ada.Containers, Ada.Finalization, Ada.Numerics.Float_Random, Ada.Numerics.Generic_Real_Arrays, or Ada.Numerics.Big_Numbers.Big_Integers. The `Light` profile removes the components that require those units:

- the three random number generators in "src/random_numbers/".
- Kalman_Filters_Linear in "src/numerics/".
- Time_Stamps in "src/images/".
- Sort_Routines in "src/sorting_searching/", with Permutation_Utils and Sorting_Proof_Utils in "src/proof_utils/" and the SPARKlib subset in "src/sparklib/".

Five of those directories hold components that a light runtime does compile: Math_Utilities and Machine_Unsigned_Types, Fixed_Point_Images and Floating_Point_Images, Search_Routines, Boolean_Array_Extent and Boolean_Array_Iteration. "proven_components.gpr" keeps those directories in the source directory list, and removes the other units one by one with the Excluded_Source_Files attribute. The runtime does not change the proof results. The instantiations in "proof/src/" that this profile compiles prove against a light runtime with the same results as against the embedded runtime.

Alire clients set the value in the manifest of the client:

```toml
[configuration.values]
proven_components.Profile = "Embedded"
```

"Profile" is a crate configuration variable, not a gprbuild external. Thus its value goes to the project file through "config/proven_components_config.gpr", which Alire makes, and not through a `-X` argument. Each profile has a different object directory, "obj/Full", "obj/Embedded", or "obj/Light". Thus object files do not mix when you change from one profile to another.

### Controlling Runtime Checks

***If you do not prove clients too, you must not disable the execution of preconditions at run-time.*** Preconditions are not only for proof. They are functional: they verify the conditions that are necessary for well-defined behavior. The subprogram declarations include these preconditions. Thus the bodies do not include them.

For example, the body of procedure Pop in the stack ADT is as follows:

```ada
procedure Pop (This : in out Stack; Item : out Element) is
begin
   Item := This.Values (This.Top);
   This.Top := This.Top - 1;
end Pop;
```

The declaration of procedure Pop includes a functional precondition. This precondition verifies that the stack contains something to remove, that is, that the stack is not empty:

```ada
procedure Pop (This : in out Stack;  Item : out Element) with
  Pre  => not Empty (This),
  Post => not Full (This)                       and then
          Item = Top_Element (This'Old)         and then
          Extent (This) = Extent (This'Old) - 1 and then
          Unchanged (This, Within => This'Old),
  Global => null;
```

Function Empty examines whether`This.Top` is zero, and thus whether `This.Top` is a correct index. Thus the program must evaluate the expression `not Empty (This)` before the body executes safely. The precondition is also necessary for proof of the body, but that is a different point.

It is also good to enable other kinds of assertion, for example predicates.

The "-gnata" switch is a tempting method to make sure that these assertions execute at run-time, because it enables *all* assertions. But this switch can cause the compiler to reject the compilation. The problem is "ghost code,"  which we almost always do not want to execute. Ghost code is used for proof and is often prohibitively expensive, although not necessarily. But by definition it is not functional code.

Therefore, the problem is that we want some kinds of assertion executed, especially preconditions, but not ghost code. These two policy choices do not agree if the enabled assertions reference ghost code. The compiler then rejects the compilation unit. The two pragmas Assert and Loop_Invariant frequently reference ghost code, but preconditions may contain ghost code too. Some of the components in the SPARKLib crate do. The proof for one of the components in Proven_Components calls such a SPARK component, causing the compiler to reject the compilation.

In these conditions, you can apply pragma Assertion_Policy as an alternative to the compiler switch. Then you can control which assertions are enabled and which are disabled, one at a time. For example, you can apply this pragma to an instantiation:

```ada
pragma Assertion_Policy (Pre                       => Check,
                         Pre'Class                 => Check,
                         Static_Predicate          => Check,
                         Dynamic_Predicate         => Check,
                         Type_Invariant            => Check,
                         Type_Invariant'Class      => Check,
                         Default_Initial_Condition => Ignore,
                         Assert                    => Ignore,
                         Ghost                     => Ignore,
                         Post                      => Ignore,
                         Post'Class                => Ignore);
```

In the example above, the assertions that verify conditions necessary for well-defined behavior are enabled. These assertions are `Pre`, `Pre'Class`, `Dynamic_Predicate`, `Type_Invariant` and `Type_Invariant'Class`. (Note that additional kinds of checks may be specified.)

The other assertions are disabled in the above. Ghost is disabled to make sure that ghost code does not execute. Assert, Post, Post'Class and Default_Initial_Condition are also disabled. It is good to enable these four during development, but they are not necessary for safe execution. 

We recommend the example above, but it is only an example. The important point is that clients can disable specified checks that contain ghost code. Then the policies agree.

A good general design rule is that preconditions must not contain ghost code if you can prevent it. All the components obey that design rule at this time, but this can change. Some routines of components have no preconditions. Thus for those routines, the policy for a precondition and the policy for ghost code always agree.

As an alternative, clients can put pragma Assertion_Policy in the "configuration pragmas" file of a project. Then it applies automatically. For details about how to do this with GNAT, refer to [The Configuration Pragmas Files](https://gcc.gnu.org/onlinedocs/gnat_ugn/The-Configuration-Pragmas-Files.html) in the GNAT User's Guide for Native Platforms. But this method for all of a project is possibly not applicable in all conditions. Pragma Assertion_Policy on individual files is the the most general method.

There is one limit on where you can put the pragma. For a library of generics, one policy controls if a ghost reference is legal. It is the policy in effect at the outermost non-generic instantiation site. If you put pragma Assertion_Policy in the generic that contains the contract, it has no effect. Only the pragma on the instantiation controls this.

## Project Dependencies

This project uses SPARKlib to prove some of the components. But at this time it does not use the SPARKlib crate as a dependency. The with-clause for "sparklib.gpr" in "proven_components.gpr" is not active at this time. A subset of 13 files from SPARKlib 15.1.0, which I selected, is copied into "src/sparklib/" as an alternative. Thus a SPARKlib of their own is not necessary for clients, and a reference to "sparklib.gpr" is also not necessary.

### The Cause of the Local Copy of the SPARKlib Sources

Two different problems made the local copy necessary. It is a workaround, not a design decision.

**The crate could not be cross-compiled.** SPARKlib 16.x declares `depends-on gnat >= 16`. On 2026-08-03, each cross-compiler crate in the Alire community index has a version that is too low: `gnat_arm_elf` stops at 15.3.1, and only `gnat_native` has version 16.1.0. This is more than a solver constraint that a version override can correct. The SPARKlib 16 sources use pragma Assertion_Level, which is a GNAT 16 feature. Thus if you specify that version, the problem only moves into the compiler.

As a result, each embedded client of these components cannot use SPARKlib 16 while that gap continues.

**SPARKlib 15 does not agree with the assertion policy recommended above.** `SPARK.Containers.Functional.Multisets` applies the Ghost function Invariant in two Type_Invariant aspects. It also applies that function in preconditions on some subprograms that are local to its body. A client that enables Pre and Type_Invariant, but ignores Ghost, is rejected with "incompatible ghost policies in effect". The section Controlling Runtime Checks gives the policy that controls this. It is the policy at the outermost non-generic instantiation. Thus you cannot repair this in SPARKlib, or in a generic that uses SPARKlib.

The local copy has `pragma Assertion_Policy (Pre => Ignore, Type_Invariant => Ignore);` at the top of the applicable spec and body. The same pragma is at the three instantiation sites in "src/proof_utils/permutation_utils.ads", "src/proof_utils/sorting_proof_utils.ads" and "src/sorting_searching/sort_routines.ads". The two parts do not operate without each other.

The closure is copied, and not the full library, to keep the cost low. Only `SPARK.Big_Integers` and `SPARK.Containers.Functional.Multisets` are the entry points to the 13 files.

The copy is not the same as the source. Together with the assertion policy pragma above, the multisets body contains one `#if SPARK_BODY_MODE` directive. I changed that directive to `with SPARK_Mode => Off` on the package body. Thus the preprocessing step of the SPARKlib crate is not necessary for these sources. A `-gnateDSPARK_BODY_MODE` switch is also not necessary.

### The plan for SPARKlib 16

SPARKlib 16 removes the second problem fully. It connects the two sides of the ghost problem to a named assertion level. It applies `Ghost => SPARKlib_Full` to the declaration, and `Type_Invariant => (SPARKlib_Full => Invariant (...))` to the use. Thus a general `Ghost => Ignore` from a client can no longer cause a mismatch between the declaration and the use. 

Proven_Components are intended for both native compilation and cross-compilation. However, SPARKlib 16 requires a cross-compiler at version 16, or a subsequent version, in the Alire index. We expect to move to SPRKlib 16 as soon as possible.

## More Project Files and Source Directories

There is a second GNAT project file, "proof/proven_components_proof.gpr", together with the project file of the components. Developers use it to prove the components during development. Its primary artifact is one more source directory, "proof/src", which contains instantiations of the components. The SPARK provers (gnatprove) examine these instantiations, because they cannot examine or prove generic units directly. Only this project file references that source folder.

This GNAT project file is not for users of the library. But you can use it if you want to start gnatprove on the components.

The "proof/src" directory also contains simple demonstration main programs. You can build these programs and then start them. Usually you can prove them too. The "MAIN" scenario variable controls which demonstration main procedure the builder builds. It defaults to "demo_buffers", if you use the "proven_components_proof.gpr" project file to build or to start GNAT Studio.

`MAIN` is a correct gprbuild external, which is not the same as `Profile`. Thus you set it on the command line, for example `-XMAIN=demo_sorts`.

Last, the builder uses "proof/obj" to compile and to prove that code. This directory is distinct from the object directory that clients reference through the project file.
