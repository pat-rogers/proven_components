# Proven Components

This project contains general purpose, reusable components written in SPARK/Ada. They are selected from a set of Ada components that I have created and used over the past few decades of Ada development (since 1980). I recently revised them for the sake of formal verification using SPARK.

Each component has been verified, usually to the Gold or Platinum level, i.e., the highest SPARK levels. All components are proven at least to the Silver level.

As such, each component is proven to be free of run-time errors, including array indexing errors, numeric range errors, numeric overflow/underflow errors, reads of unassigned variables, unintended access to global data, and others.

In addition to those benefits, proof at the Gold level ensures that the provided operations implement their functional requirements at the unit level, obviating unit tests (or, if exercised, ensuring that the tests pass on their first attempt). Proof at the Platinum level is similar, except that the functional requirements are fully expressed for each unit (and proven).

For a detailed description of the proof levels and their benefits, see the SPARK User Guide, starting in the section at this URL:
https://docs.adacore.com/spark2014-docs/html/ug/en/usage_scenarios.html#levels-of-spark-use

The subsection describing the Silver level is here:
https://docs.adacore.com/spark2014-docs/html/ug/en/usage_scenarios.html#silver-level-absence-of-run-time-errors-aorte

## The Components

The components are located entirely in the src/ directory tree, grouped by functionality into subdirectories.

### Unit Names

The names of the generic packages, and hence their files' names, typically reflect specific characteristics of the components. For example:

- whether objects of the type are thread-safe
- whether objects of the type are bounded or unbounded in their memory usage
- the general abstraction itself

Thread-safety is indicated by either "sequential" or "concurrent" appearing in the name. Memory usage is indicated by either "bounded" or "unbounded" appearing in the name.

For example, the file named "sequential_bounded_buffers.ads" contains the generic package declaration for a buffer ADT. Objects of this type are not protected from concurrent access and are bounded in memory usage.

The names can contain other indicators, as needed. For example the name might
include the word "discrete" to indicate that only discrete types are supported (via the generic formal type).

### Proof Utility Components

Some of the primary components are implemented with "utility" components that facilitate proof. These utility components are defined as reusable generics so that they can be used in new components requiring verification, including client-defined components. These generic packages are located in the "src/proof_utils/" subdirectory under the source directory containing the primary components. They are part of the project managed by "proven_components.gpr" and not the separate project used for invoking the provers on test instantiations.

For example, a common implementation idiom uses an array of Boolean components, in which each individual Boolean indicates something about the value corresponding to that array component's index. A specific example is the "Set" ADT that contains member values of some discrete type. The Boolean array is indexed by the discrete "member" type. Thus each component value indicates set membership, or lack thereof, for the corresponding member index value. One of the Set operations indicates how many members are currently held by a Set object. This corresponds to the total number of Boolean components that are currently True. Other operations will add or remove an individual member of a given set, incrementing or decrementing that total. Proof of the relationship between individual array component changes and the total involves induction, requiring lemmas. Therefore, the utility generic package Boolean_Array_Extent provides a function Extent indicating the number of True components, and lemma procedures facilitating proof of the incrementing and decrementing operations. New primary components may reuse this generic package, but new user-defined components can use it too.

## Using the Library

Users specify the GNAT project file named "proven_components.gpr" in a with-clause in their projects. That will make the components available to their projects.  At the time of this writing nearly all of the components are generic units so clients are responsible for instantiating them.

There are other project files in the project root but those are not intended for clients.

### Client Compliation and Build

When building a client project that references (via with-clause) "proven_components.gpr", the GNAT builder will build these components automatically. Note that the component's object files will go in the "obj" directory local to the Proven_Components project, rather than in client project object directories.

When building the components, the GNAT builder will apply the switches specified in the "proven_components.gpr" project file. These switches include optimization (at level O2) as well as those necessary for automatic removal of unused code and data at link-time.

Some of the components use Ada 2022 syntax so that corresponding switch is applied when the components are built.

At the time of the initial project release, the following versions of the GNAT FSF tools were used:

- gnatprove-x86_64-windows64-15.1.0-1

- gnat-x86_64-windows64-15.2.0-1

- gprbuild-x86_64-windows64-25.0.0-1

### Controlling Runtime Checks

***Unless you prove clients too, you should not disable execution of preconditions at run-time***, because they are not just for proof, i.e., they are functional: they verify conditions required for well-defined behavior. The subprogram declarations include these preconditions so the bodies do not. For example, the body of procedure Pop in the stack ADT is as follows:

```ada
procedure Pop (This : in out Stack; Item : out Element) is
begin
   Item := This.Values (This.Top);
   This.Top := This.Top - 1;
end Pop;
```

The declaration of procedure Pop includes a functional precondition verifying that the stack currently contains something to be removed, i.e., that it is not empty:

```ada
procedure Pop (This : in out Stack;  Item : out Element) with
  Pre  => not Empty (This),
  Post => not Full (This)                       and then
          Item = Top_Element (This'Old)         and then
          Extent (This) = Extent (This'Old) - 1 and then
          Unchanged (This, Within => This'Old),
  Global => null;
```

Specifically, function Empty checks whether `This.Top` is zero, thus whether `This.Top` is a valid index. Hence prior evaluation of the expression `not Empty (This)` must occur for safe execution of the body. (The precondition is also required for proof of the body, but that is beside the point.) 

Note that other forms of assertion are also worth enabling, such as dynamic predicates.

A convenient approach to ensuring that these assertsions are executed at run-time is to apply the "-gnata" switch that enables *all* assertions. However, this switch can result in a conflict in SPARK code, causing the compilation to be rejected. The issue is ghost code, code that we almost always want **not** to be executed. (It tends to be expensive, although not necessarily so, but then why mark it as Ghost if we want it to be executed?) Specifically, if we use the compiler switch "-gnata" to enable all assertions, but we also specify to the compiler that we want ghost code ignored, those policy choices conflict *if the assertions contain references to ghost code. The compiler will then reject the compilation unit. Both pragma Assert and Loop_Invariant are typically involved, as both are assertions that often reference ghost code.

In such cases you can instead apply pragma Assertion_Policy so that you can individually control which assertions are enabled and which are disabled. For example, you could apply the following to an instantiation:

```ada
pragma Assertion_Policy (Pre                       => Check,
                         Pre'Class                 => Check,
                         Static_Predicate          => Ignore,
                         Dynamic_Predicate         => Check,
                         Type_Invariant            => Check,
                         Type_Invariant'Class      => Check,
                         Default_Initial_Condition => Ignore,
                         Assert                    => Ignore,
                         Ghost                     => Ignore,
                         Post                      => Ignore,
                         Post'Class                => Ignore);
```

In the above, all the functional checks are enabled, except for Static_Predicate which is checked at compile-time unless the corresponding code is dealing with values coming from external sources. (In that case, the code should use 'Valid anyway.)

The above is just a suggestion. The point is that clients can disable specific checks that contain ghost code so that the policies will not conflict. Typically, preconditions are the assertions that conflict with disabled ghost code, and as a result, a good general design rule is that preconditions should not contain ghost code if avoidable. Currently all the components follow that rule, but that's not guaranteed. Some components' routines do not have preconditions, so there's no potential precondition-ghost issue for them.

Alternatively, clients can place pragma Assertion_Policy in a project's "configuration pragmas" file so that it would apply automatically and globally to the associated project. For the details of how to do that with GNAT, see the specific [documentation]([The Configuration Pragmas Files (GNAT User’s Guide for Native Platforms)](https://gcc.gnu.org/onlinedocs/gnat_ugn/The-Configuration-Pragmas-Files.html)). Note, however, that this global approach is probably not universaaly appropriate so the Assertion_Policy pragma is the recommended approach.

## Project Dependencies

This project depends upon SPARKlib for the sake of proving some of the components. Therefore, the project file "sparklib.gpr" is referenced by "proven_components.gpr".  

SPARKlib can be obtained from GitHub or as a crate in Alire. Note also that the `gnatprove` tool includes SPARKlib.

If you are using Alire, just add the dependency for "sparklib" as usual, i.e., `alr with sparklib`. Otherwise, if not using Alire, you will need a local copy of the SPARKlib gpr file or have it locatable for the tools, for example in the `GPR_Project_Path` environment variable.

Clients are not expected to reference the "sparklib.gpr" file themselves.

## Additional Project File and Source Directories

In addition to the component's project file, the other gnat project file in the root directory is "proven_components_proof.gpr", used for proving the components during development. The primary artifact of that project file is an additional source directory ("src_proof") that contains instantiations of the components. It is these instantiations that are submitted to the SPARK (gnatprove) provers, because generic units cannot be examined or proven directly, at least not with the current version of gnatprove. Only this project file references this additional source folder. Users of the library are not intended to use this GNAT project file, but there is no harm in doing so if you want to run gnatprove yourself on the components.

In addition, the "src_proof" directory contains simple demonstration main programs. You can build and run these programs, and typically you can prove them too. The "MAIN" scenario variable controls which demo main procedure is built, assuming that you are using the "proven_components_proof.gpr" project file to build or run GNAT Studio.

Finally, the directory "obj_proof" is used for compiling and proving the code, distinct from the object directory that clients indirectly reference (i.e., "obj").
