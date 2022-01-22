;; Load all the systems.
(loop
  for system-name in *system-names*
  do (asdf:load-system system-name))

;; Because the implementation may very well exit upon performing program-op, we
;; need a way to deal with that. This is gross, but what we do is we loop
;; through all the systems, building each one. When we finish building all of
;; them, we touch the file $NIX_BUILD_TOP/.clnix-finished-binaries. There's
;; then a bash loop around this that reruns this script until that file exists,
;; or we return non-zero.
(let ((bindir (merge-pathnames #p"bin/" (uiop:getenv-absolute-directory "out"))))
  (dolist (system-name *system-names*)
    (let ((path (make-pathname :defaults bindir :name system-name))
          (system (asdf:find-system system-name)))
      (when (and (eql (asdf/component:component-build-operation system) :program-op)
                 (not (probe-file path)))
        (defmethod asdf:output-files ((o asdf:image-op) (system (eql system)))
          (declare (ignorable system))
          (list path))

        (asdf:operate 'asdf:program-op system-name)))))
(with-open-file (stream (make-pathname :defaults (uiop:getenv-absolute-directory "NIX_BUILD_TOP")
                                       :name ".clnix-finished-binaries")
                        :direction :output)
  (declare (ignorable stream)))
