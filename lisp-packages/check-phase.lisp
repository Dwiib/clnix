(loop
  for system-name in *system-names*
  do (asdf:test-system system-name))
