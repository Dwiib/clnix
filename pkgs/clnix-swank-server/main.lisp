(uiop:define-package :clnix-swank-server
  (:use :cl :iterate)
  (:export #:main))
(in-package :clnix-swank-server)

(defparameter *swank-port* 4005)

(defun main (&optional (args uiop:*command-line-arguments*))
  (asdf:ensure-source-registry
    `(:source-registry
       (:directory ,(uiop:getcwd))
       :inherit-configuration))
  (parse-args args)
  (swank:create-server :port *swank-port* :dont-close t)
  (when swank:*communication-style*
    (format swank/backend:*log-output* ";; Sleeping forever...~%")
    (iter (sleep 3600))))

(defun show-usage-and-die (&optional (exit-code 1) format &rest args)
  (format *error-output* "Usage: ~a [OPTIONS...] <SYSTEMS...>~%~%"
          (or (uiop:argv0) "clnix-swank-server"))
  (format *error-output* "A simple helper to start a Swank server from the command line.~%~%")
  (format *error-output* "Options:~%~%")
  (format *error-output* "  --communication-style STYLE~%~%")
  (format *error-output*
          "    Configures how Lisp reads messages from the editor. Valid values of STYLE~%")
  (format *error-output*
          "    are default, nil, fd-handler, sigio, and spawn. For more information about~%")
  (format *error-output*
          "    what these values mean, see the SLIME documentation at:~%")
  (format *error-output*
          "    https://slime.common-lisp.dev/doc/html/Communication-style.html~%~%")
  (format *error-output* "  --port PORT~%~%")
  (format *error-output*
          "    Set the port number on which Lisp listens for messages from the editor.~%")
  (format *error-output* "    Defaults to 4005.~%~%")
  (format *error-output* "  SYSTEMS...~%~%")
  (format *error-output*
          "    Any other arguments will be treated as the names of ASDF systems to load~%")
  (format *error-output*
          "    before starting the server.~%")

  (if format
      (apply #'uiop:die exit-code format args)
      (uiop:quit exit-code)))

(defun parse-communication-style (arg)
  (cond
    ((string= arg "default")
     (swank-backend::preferred-communication-style))
    ((string= arg "fd-handler") :fd-handler)
    ((string= arg "nil") nil)
    ((string= arg "sigio") :sigio)
    ((string= arg "spawn") :spawn)
    (t (show-usage-and-die 1 "Unrecognized communication style ~s" arg))))

(defun parse-args (args)
  (iter
    (while args)
    (cond
      ((or (string= (car args) "-h")
           (string= (car args) "--help"))
       (show-usage-and-die 0))
      ((string= (car args) "--communication-style")
       (unless (cdr args)
         (show-usage-and-die 1 "Missing argument to --communication-style"))
       (setf swank:*communication-style* (parse-communication-style (cadr args))
             args (cddr args)))
      ((string= (car args) "--port")
       (unless (cdr args)
         (show-usage-and-die 1 "Missing argument to --port"))
       (setf *swank-port* (parse-integer (cadr args))
             args (cddr args)))
      (t
       (asdf:load-system (car args))
       (setf args (cdr args))))))
