(defsystem "clnix-swank-server"
  :author "Nathan Ringo <nathan@remexre.xyz>"
  :build-operation :program-op
  :components ((:file "main"))
  :depends-on ("iterate" "swank")
  :description "A simple helper to start a Swank server from the command line."
  :entry-point "CLNIX-SWANK-SERVER:MAIN"
  :license "CC0-1.0"
  :version "0.0.1")

; vi: set ft=lisp :
