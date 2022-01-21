(require 'asdf)

(defun system-names ()
  (let ((string (uiop:getenv "asdfSystemNames")))
    (nconc
      (loop
        for i = (position #\Space string)
        while i
        collect (subseq string 0 i)
        do (setf string (subseq string (1+ i) (length string))))
      (list string))))
(defvar *system-names* (system-names))
