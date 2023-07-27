clnix
=====

An alternative packaging for Common Lisp packages in Nix.

Philosophy:

- Be as compatible with `stdenv.mkDerivation` as possible.
- Bug upstreams before doing anything gross.
- Build as much of Quicklisp as is practical, but reasonable code is more important than 100% coverage.
- If it felt non-obvious (rule-of-thumb: did it take >10min?), comment!
- Provide a recent (<1 year old) ASDF, replacing the one in the implementation if necessary.

Non-Goals:

- Broad compiler support (yet!).
  I personally pretty much only use SBCL.
  Patches and requests for additional implementations are welcome on the [mailing list].
- Broad platform support (yet!).
  Currently, the flake is available on `aarch64-darwin`, `aarch64-linux`, `i686-linux`, `x86_64-darwin`, and `x86_64-linux`.
  However, I personally pretty much only use `aarch64-linux` and `x86_64-linux`, so these platforms are the only ones getting significant testing.
  This may improve once I set up a Hydra install with access to `aarch64-darwin` and `x86_64-darwin` builders; it'd be nice to build the world every commit.
  Patches to improve support for other platforms are welcome on the [mailing list].
- FHS-ish `$out` layout.

Status
------

clnix should probably be considered experimental until it's been able to build all of Quicklisp on all the platforms the flake is available for, on at least two Lisp implementations, for at least 3 months or so.
If you choose to use it anyway, bug reports would be extremely welcome on the [mailing list].

I'm currently using clnix to build my thesis work, and I plan to support it through at least 2023-01-01.

As of 2022-01-23, clnix has the following issues on the 5050 systems in Quicklisp on x86_64-linux:

- skips building 2 systems due to known brokenness
- skips building 91 systems due to known brokenness in dependencies
- fails to build 429 systems due to uncategorized build errors
- skips building 886 systems due to uncategorized build errors in dependencies

This is a 72% build success rate overall.

By comparison, nixpkgs currently has 252 systems in `pkgs/development/lisp-modules/quicklisp-to-nix-systems.txt`.
clnix builds all of these on aarch64-linux and x86_64-linux.

On aarch64-linux, the numbers are 2, 91, 438, 958, and 71%; and all the systems from `quicklisp-to-nix-systems.txt` can be built.
More investigation is needed as to which systems fail here in particular.

API
---

```
$ nix repl
Welcome to Nix 2.5.1. Type :? for help.

nix-repl> :lf git+https://git.sr.ht/~remexre/clnix?ref=trunk
Added 14 variables.
```

### Implementations

For each implementation we support, there is an appropriately-named package.

```
nix-repl> sbcl = outputs.packages.aarch64-linux.sbcl

nix-repl> sbcl
«derivation /nix/store/ylhslm377dnaklszm0hgh7sqbj7cx936-sbcl-2.1.11.drv»
```

The implementations are the nixpkgs versions, patched to use recent versions of ASDF.

### lispPackages

Each implementation then has a `packages` attribute, which is a scope (like `pythonPackages` in nixpkgs) that contains a Nix package for each Lisp system (not project!) on Quicklisp.
Colloquially this is called lispPackages (despite not being an attribute with that exact name).
Some other projects not on Quicklisp are packaged as well; patches to add more are welcomed.

```
nix-repl> sbcl.packages.alexandria
«derivation /nix/store/vqhdi4yg095a2mc5gdl8yixgwv8jgj35-ql-alexandria-20211209-git.drv»

nix-repl> sbcl.packages.coalton
«derivation /nix/store/b017jb7w5fsfv1dfyxilbxxjnvk7sfik-coalton-20220113-git.drv»
```

Since lispPackages is a scope, one can use `callPackage` with it, which behaves as one would expect.
See the Recipes section below for examples of its use.

```
nix-repl> sbcl.packages.callPackage
«lambda @ /nix/store/nyg84l8l13kic8g3mxcczi71sjr6vm0g-source/lib/customisation.nix:117:31»
```

A `mkDerivation` wrapper is also provided.
This provides helpful defaults for various phases to try and "do the right thing" when building a system using ASDF.
See the Recipes section below for examples of its use, or `lisp-packages/make-derivation.nix` for its definition.

```
nix-repl> sbcl.packages.mkDerivation
{ __functionArgs = { ... }; __functor = «lambda @ /nix/store/nyg84l8l13kic8g3mxcczi71sjr6vm0g-source/lib/trivial.nix:385:19»; override = { ... }; }
```

### clnix-swank-server

A simple helper binary, `clnix-swank-server`, is provided on the `swank` attribute of each implementation.
This is also provided in lispPackages.

```
nix-repl> sbcl.swank
«derivation /nix/store/alvlj6603r3s5vhry883dvz0nl09kyll-clnix-swank-server-0.0.1.drv»

nix-repl> sbcl.packages.clnix-swank-server
«derivation /nix/store/alvlj6603r3s5vhry883dvz0nl09kyll-clnix-swank-server-0.0.1.drv»
```

Recipes
-------

### Building a System

In flake.nix, or anywhere else:

```nix
let sbcl = clnix.packages.${system}.sbcl;
 in sbcl.packages.callPackage ./my-package.nix {};
```

In `my-package.nix`:

```nix
{ alexandria, closer-mop, iterate, mkDerivation }:

mkDerivation {
  pname = "my-package";
  version = "0.1.0";
  src = ./.;
  propagatedBuildInputs = [ alexandria closer-mop iterate ];
};
```

This derivation will compile the ASDF system `my-package`, which should be defined in `my-package.asd` inside the `src`.
If you have multiple systems to compile, or the system is named something different than the derivation, you can use the `asdfSystemNames` attribute.
This is a list of strings, where each string is the name of a system to be compiled.

The `mkDerivation` wrapper passes any arguments it doesn't understand along to `stdenv.mkDerivation`, so it's fine to pass whatever else you want.

Any systems that specify a `:build-operation` of `:program-op` are automatically compiled to binaries.
They should also specify `:entry-point`s.
The resulting binaries are in `$out/bin`, with the same name as the system.

### Starting a Swank Server

The `clnix-swank-server` helper binary can be used to start a Swank server.
An example of using it:

```nix
{ alexandria, clnix-swank-server, closer-mop, iterate, mkDerivation, mkShell }:

let
  my-package = mkDerivation {
    pname = "my-package";
    version = "0.1.0";
    src = ./.;

    propagatedBuildInputs = [ alexandria closer-mop iterate ];

    passthru.devShell = mkShell {
      inputsFrom = [ my-package ];
      nativeBuildInputs = [ clnix-swank-server ];
    };
  };

in my-package
```

Then, after doing `nix develop .#my-package.devShell`, run `clnix-swank-server` from the directory `my-package.asd` is in.
This should start a Swank server on port 4005 that is able to load `my-package` and any of its dependencies.

Troubleshooting
---------------

### `Can't create directory /homeless-shelter`

Something tried to create a directory inside the home directory.
The right solution is *probably* to mess with `ASDF_OUTPUT_TRANSLATIONS`.
This variable controls where the results of building sources go.
See [the ASDF manual] for more details about it.

An example `postConfigure` to fix this might be like:

```nix
postConfigure = ''
  ASDF_OUTPUT_TRANSLATIONS="/tmp/extra-srcs:$out/lib:''${ASDF_OUTPUT_TRANSLATIONS:-}"
'';
```

Note that:

- This intentionally doesn't use `addToSearchPath`.
  We typically want to prepend to `ASDF_OUTPUT_TRANSLATIONS` rather than append.
  The older entries (added by dependencies' setup hooks) should be later, since if a dependency defines a system that we also define, ours needs to be taken to avoid ASDF attempting to write compiler output to the dependency's directory in the Nix store.
- This intentionally leaves a trailing colon.
  The semantics of a trailing colon in `ASDF_OUTPUT_TRANSLATIONS` are to continue inheriting configuration.
  If any exists, we probably want it!
  (This ought to be pretty rare when building packages, but might occur when a user is developing.)

Also consider that the source files probably need to be moved to somewhere under `$out` to be read later; if so, a similar tweak to the above belongs in the setup hook.

Justifications
--------------

### Why is Quicklisp exposed at the system level rather than the project level?

Quicklisp's design does not require that the transitive closure of the project dependency relation be a DAG, and indeed, there are several circular dependencies.
This mostly occurs because of test systems.

Older versions of clnix tried to explicitly support building multiple projects together to avoid the circular dependencies.
However, there's a [huge circularity] containing many commonly-used packages.

Actually building them this way would result in pulling in a large number of native-code dependencies and having a very long compile in order to use any of them.
Additional care would also be required to split them back out after building, to avoid e.g. `cffi` having a dependency on `libmysqlclient.so`!

### Why patch implementations?

Implementations are rather conservative in updating ASDF.
Recent versions of ASDF are necessary in order to have features like package-local-nicknames and package-inferred-system work together without drastic hacks that make `asdf:find-system` side-effecting.

Every system in Quicklisp already depends on `asdf`, so a more recent version would get loaded anyway as soon as a dependency is loaded.
Patching the implementation to use the same version the Quicklisp-provided systems would use just makes the overall developer experience more consistent.

Developer Notes
---------------

- Anything in `scripts/` should work inside the `devShell`.
  I use direnv, but `nix develop` ought to work too.
- Quicklisp metadata is fetched by `scripts/update-distinfo.pl` and written to a JSON file of the form `quicklisp/dist-$version.json`.
  This is then symlinked to `quicklisp/dist-latest.json`.
  We don't yet normalize the JSON to make diffing easier, patches welcome on the [mailing list].
- Since Quicklisp uses MD5 hashes, which Nix rightfully stopped supporting ages ago, we need to translate them to SHA256 hashes.
  `quicklisp/hashes.json` contains the translation.
  Run `scripts/update-hashes.pl` to add every hash mentioned in a JSON'd distinfo file to it.
  Note that this entails fetching the referenced files, so it might be somewhat slow.
- At some point, it'd be nice to extract more metadata from Quicklisp systems; at least description, homepage, license, and long-description
  - Possibly also which systems use certain build-operations, to detect binaries?
  - Possibly also the systems used for testing, in order to expose tests through `passthru.tests`?

Licensing
---------

The code in the clnix repo is offered under the CC0 license.
Note that this does not affect the license of any derivation this flake exports that comes from external code; they each have their own licenses.

[huge circularity]: https://git.sr.ht/~remexre/clnix/tree/58c27023c01341f23b5d57da2be70a07c7135e66/item/quicklisp/overrides.nix#L7
[mailing list]: https://lists.sr.ht/~remexre/clnix
[the ASDF manual]: https://asdf.common-lisp.dev/asdf.html
