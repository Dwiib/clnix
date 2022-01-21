clnix
=====

An alternative packaging for Common Lisp packages in Nix.

Philosophy:

- Be as compatible with `stdenv.mkDerivation` as possible.
- Bug ASDF maintainers before doing anything gross.
- Build as much of Quicklisp as is practical, but reasonable code is more important than 100% coverage.
- If it felt non-obvious (rule-of-thumb: did it take >10min?), comment!
- Provide a recent (<1 year old) ASDF, replacing the one in the implementation if necessary.

Non-Goals:

- Binary packaging.
  See the below section.
- Broad compiler support.
  I personally pretty much only use SBCL.
- Broad platform support.
  I personally pretty much only use `aarch64-linux` and `x86_64-linux`.
- FHS-ish `$out` layout.

Binary Packaging
----------------

Currently, the `mkDerivation` function doesn't automatically build binaries for Quicklisp packages.

TODO: Have an option to build binaries?

TODO: Have a separate function to make a "clean" binary package, with a runtime closure that doesn't include the Lisp library derivations?

Recipes
-------

TODO: A recipe for building a library (nrutil?)

TODO: A recipe for building a binary (sylvan?)

TODO: A recipe for starting Swank

Troubleshooting
---------------

### `Can't create directory /homeless-shelter`

Something tried to create a directory inside the home directory.
The right solution is *probably* to mess with `ASDF_OUTPUT_TRANSLATIONS`.
This variable controls where the results of building sources go.
See the ASDF manual for more details about it.

An example `postConfigure` to fix this might be like:

```bash
addToSearchPath ASDF_OUTPUT_TRANSLATIONS "$TMPDIR/extra-srcs"
addToSearchPath ASDF_OUTPUT_TRANSLATIONS "$out/lib"
```

Note that for `addToSearchPath` to work, the directory must exist.

### `error: infinite recursion` when evaluating Quicklisp package

Quicklisp can and does have circular dependencies between *projects*.
This is fine outside of Nix, because dependencies between *systems* are acyclic.
We resolve this by having sets of projects that must be built together in the `combined` attribute in `quicklisp/overrides.nix`.

The `debugNix` option may be useful:

```console
$ nix repl
nix-repl> :lf .
Added 11 variables.

nix-repl> p = outputs.packages.aarch64-linux.sbcl.packages.override { debugNix = true; }

nix-repl> p.the-broken-project
trace: Evaluating the-broken-project
trace: Evaluating dependent-project-1
trace: Evaluating dependent-project-2
trace: Evaluating some-other-thing
trace: Evaluating dependent-project-3
error: infinite recursion encountered
```

In this example, `the-broken-project` is probably one of `dependent-project-3`'s dependencies, possibly indirectly.
A simple strategy for finding what should be combined is to go through the systems that were printed, and collecting all of them that also fail with an infinite recursion.
This will not, however, find the minimum combined derivation size.

Developer Notes
---------------

- Anything in `scripts/` should work inside the `devShell`.
  I use direnv, but `nix develop` ought to work too.
