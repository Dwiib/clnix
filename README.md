# clnix

An alternative packaging for Common Lisp packages in Nix.

Philosophy:

- Be as compatible with `stdenv.mkDerivation` as possible.
- Bug ASDF maintainers before doing anything gross.
- Build all of QuickLisp.
- If it felt non-obvious (rule-of-thumb: did it take >10min?), comment!
- Provide a recent (<1 year old) ASDF, replacing the one in the implementation if necessary.

Non-Goals:

- Broad compiler support.
- Broad platform support.
- FHS-ish `$out` layout.

## Other Notes

- Anything in `scripts/` should work inside the `devShell`.
  I use direnv, but `nix develop` ought to work too.
