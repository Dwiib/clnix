(loop
  for system-name in *system-names*
  do (asdf:load-system system-name))
