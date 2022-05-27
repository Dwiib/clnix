{ cairo, fuse, gdk-pixbuf, glfw, glib, gobject-introspection, gsl, gtk3, hdf5
, libev, libffi, libfixposix, libglvnd, libuv, lispPackages, mysql-client
, openblas, openssl, pango, pkg-config, protobuf, postgresql, qt4, sqlite
, webkitgtk, zeromq, zstd }:

{
  exclude-from-allQuicklispSystems = [
    # https://github.com/mmaul/clml/pull/49
    "clml"
    "clml.data"
    "clml.data.r-datasets"
    "clml.data.r-datasets-package"

    # cl-ana.hdf-cffi is broken, see below.
    "cl-ana"
    "cl-ana.hdf-cffi"
    "cl-ana.hdf-table"
    "cl-ana.hdf-typespec"
    "cl-ana.hdf-utils"
    "cl-ana.histogram"
    "cl-ana.makeres"
    "cl-ana.makeres-block"
    "cl-ana.makeres-branch"
    "cl-ana.makeres-graphviz"
    "cl-ana.makeres-macro"
    "cl-ana.makeres-progress"
    "cl-ana.makeres-table"
    "cl-ana.makeres-utils"
    "cl-ana.serialization"

    # qt-libs is broken, see below.
    "commonqt"
    "flare-viewer"
    "flow-visualizer"
    "halftone"
    "lionchat"
    "phonon"
    "q+"
    "qimageblitz"
    "qsci"
    "qt"
    "qt+libs"
    "qt-lib-generator"
    "qt-libs"
    "qt-repl"
    "qt-test"
    "qt-tutorial"
    "qt3support"
    "qtcore"
    "qtdbus"
    "qtdeclarative"
    "qtgui"
    "qthelp"
    "qtnetwork"
    "qtools"
    "qtools-evaluator"
    "qtools-game"
    "qtools-helloworld"
    "qtools-melody"
    "qtools-opengl"
    "qtools-titter"
    "qtools-ui"
    "qtools-ui-auto-resizing-textedit"
    "qtools-ui-base"
    "qtools-ui-bytearray"
    "qtools-ui-cell"
    "qtools-ui-color-history"
    "qtools-ui-color-picker"
    "qtools-ui-color-sliders"
    "qtools-ui-color-triangle"
    "qtools-ui-compass"
    "qtools-ui-container"
    "qtools-ui-debugger"
    "qtools-ui-dialog"
    "qtools-ui-dictionary"
    "qtools-ui-drag-and-drop"
    "qtools-ui-executable"
    "qtools-ui-fixed-qtextedit"
    "qtools-ui-flow-layout"
    "qtools-ui-helpers"
    "qtools-ui-imagetools"
    "qtools-ui-keychord-editor"
    "qtools-ui-layout"
    "qtools-ui-listing"
    "qtools-ui-notification"
    "qtools-ui-options"
    "qtools-ui-panels"
    "qtools-ui-placeholder-text-edit"
    "qtools-ui-plot"
    "qtools-ui-progress-bar"
    "qtools-ui-repl"
    "qtools-ui-slider"
    "qtools-ui-spellchecked-text-edit"
    "qtools-ui-splitter"
    "qtools-ui-svgtools"
    "qtopengl"
    "qtscript"
    "qtsql"
    "qtsvg"
    "qttest"
    "qtuitools"
    "qtwebkit"
    "qtxml"
    "qtxmlpatterns"
    "qwt"
    "random-state-viewer"
    "smokebase"
  ];
  systems = {
    # These systems ought to be using complex component names, but... aren't.
    # This breaks loading them without loading the system whose .asd file
    # they're defined in.
    "cl-async-base" = old: {
      asdfSystemNames = [ "cl-async" ] ++ old.asdfSystemNames;

      # Since we load cl-async, we need its dependencies, too. This creates a
      # loop if we just do
      #
      #   propagatedBuildInputs = old.propagatedBuildInputs
      #     ++ lispPackages.cl-async.propagatedBuildInputs
      #     ++ lispPackages.cl-async-util.propagatedBuildInputs;
      #
      # so instead, we list them out.
      propagatedBuildInputs = [
        lispPackages.babel
        lispPackages.bordeaux-threads
        lispPackages.cffi
        lispPackages.cl-libuv
        lispPackages.cl-ppcre
        lispPackages.fast-io
        lispPackages.static-vectors
        lispPackages.trivial-features
        lispPackages.trivial-gray-streams
        lispPackages.uiop
        lispPackages.vom
      ];
    };
    "cl-async-util" = old: {
      asdfSystemNames = [ "cl-async" ] ++ old.asdfSystemNames;

      # The same issues as for cl-async-base apply (same bug, really).
      propagatedBuildInputs = [
        lispPackages.babel
        lispPackages.bordeaux-threads
        lispPackages.cffi
        lispPackages.cl-libuv
        lispPackages.cl-ppcre
        lispPackages.fast-io
        lispPackages.static-vectors
        lispPackages.trivial-features
        lispPackages.trivial-gray-streams
        lispPackages.uiop
        lispPackages.vom
      ];
    };
    "cl-json.test" = old: {
      asdfSystemNames = [ "cl-json" ] ++ old.asdfSystemNames;
    };
    "curly.test" = old: {
      asdfSystemNames = [ "curly" ] ++ old.asdfSystemNames;
    };
    "ucw-core.test" = old: {
      asdfSystemNames = [ "ucw-core" ] ++ old.asdfSystemNames;

      # ASDF issues another warning:
      #
      # Deprecated recursive use of (ASDF/OPERATE:OPERATE 'ASDF/LISP-ACTION:LOAD-OP
      # '("ucw.httpd")) while visiting
      # (ASDF/LISP-ACTION:LOAD-OP "ucw-core.test" "test" "test-environment") -
      # please use proper dependencies instead
      #
      # and then dies, unable to find rfc2388-binary. Adding it as an input
      # seems to fix this?
      #
      # TODO: Should Quicklisp's dependency info have rfc2388-binary listed as
      # a dependency?
      propagatedBuildInputs = old.propagatedBuildInputs
        ++ [ lispPackages.rfc2388-binary ];
    };
    "zeromq.tests" = old: {
      asdfSystemNames = [ "zeromq" ] ++ old.asdfSystemNames;
    };

    # These systems just need some non-Lisp dependencies for CFFI. This
    # typically requires patching the cffi:define-foreign-library form to pass
    # an absolute path to the nixpkgs library we want the system to use.
    "cffi-libffi" = old: {
      buildInputs = [ libffi ];
      # This is technically a breaking change, but... it's probably fine.
      patchPhase = ''
        sed -i cffi_${old.version}/libffi/libffi.lisp \
          -e 's|"libffi.so.7"|"${libffi}/lib/libffi.so.8"|'
      '';
    };
    "cl+ssl" = old: {
      patchPhase = ''
        sed -i cl+ssl-${old.version}/src/reload.lisp \
          -e 's|"libcrypto.so.1.1"|"${openssl.out}/lib/libcrypto.so.1.1"|' \
          -e 's|"libssl.so.1.1"|"${openssl.out}/lib/libssl.so.1.1"|'
      '';
    };
    "cl-ana.hdf-cffi" = old: {
      buildInputs = [ hdf5 ];
      nativeBuildInputs = old.nativeBuildInputs ++ [ pkg-config ];
      patchPhase = ''
        sed -i cl-ana-${old.version}/hdf-cffi/src/library.lisp \
          -e 's|"libhdf5.so"|"${hdf5}/lib/libhdf5.so"|'
      '';

      # nixpkgs doesn't ship the hdf5 pkg-config file?
      meta.broken = true;
    };
    "cl-async-ssl" = old: {
      patchPhase = ''
        sed -i cl-async-${old.version}/src/ssl/package.lisp \
          -e 's|"libcrypto.so.1.1"|"${openssl.out}/lib/libcrypto.so.1.1"|' \
          -e 's|"libssl.so.1.1"|"${openssl.out}/lib/libssl.so.1.1"|'
      '';
    };
    "cl-cffi-gtk-cairo" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/cairo/cairo.init.lisp \
          -e 's|"libcairo.so.2"|"${cairo}/lib/libcairo.so.2"|'
      '';
    };
    "cl-cffi-gtk-gdk" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/gdk/gdk.package.lisp \
          -e 's|"libgtk-3.so.0"|"${gtk3}/lib/libgtk-3.so.0"|'
      '';
    };
    "cl-cffi-gtk-gdk-pixbuf" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/gdk-pixbuf/gdk-pixbuf.init.lisp \
          -e 's|"libgdk_pixbuf-2.0.so.0"|"${gdk-pixbuf}/lib/libgdk_pixbuf-2.0.so.0"|'
      '';
    };
    "cl-cffi-gtk-glib" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/glib/glib.init.lisp \
          -e 's|"libglib-2.0.so.0"|"${glib.out}/lib/libglib-2.0.so.0"|' \
          -e 's|"libgthread-2.0.so.0"|"${glib.out}/lib/libgthread-2.0.so.0"|'
      '';
    };
    "cl-cffi-gtk-gobject" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/gobject/gobject.init.lisp \
          -e 's|"libgobject-2.0.so.0"|"${glib.out}/lib/libgobject-2.0.so.0"|'
      '';
    };
    "cl-cffi-gtk-gio" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/gio/gio.init.lisp \
          -e 's|"libgio-2.0.so.0"|"${glib.out}/lib/libgio-2.0.so.0"|'
      '';
    };
    "cl-cffi-gtk-pango" = old: {
      patchPhase = ''
        sed -i cl-cffi-gtk-${old.version}/pango/pango.init.lisp \
          -e 's|"libpango-1.0.so.0"|"${pango.out}/lib/libpango-1.0.so.0"|' \
          -e 's|"libpangocairo-1.0.so.0"|"${pango.out}/lib/libpangocairo-1.0.so.0"|'
      '';
    };
    "cl-fuse" = old: {
      buildInputs = [ fuse ];
      patchPhase = ''
        sed -i cl-fuse-${old.version}/fuse-functions.lisp \
          -e 's|"libfuse"|"${fuse}/lib/libfuse"|'
      '';
    };
    "cl-glfw3" = old: {
      patchPhase = ''
        sed -i cl-glfw3-${old.version}/glfw-bindings.lisp \
          -e 's|"libglfw.so.3"|"${glfw}/lib/libglfw.so.3"|'
      '';
    };
    "cl-gobject-introspection" = old: {
      patchPhase = ''
        sed -i cl-gobject-introspection-${old.version}/src/init.lisp \
          -e 's|"libgirepository-1.0.so.1"|"${gobject-introspection}/lib/libgirepository-1.0.so.1"|' \
          -e 's|"libgobject-2.0.so.0"|"${glib.out}/lib/libgobject-2.0.so.0"|'
      '';
    };
    "cl-libuv" = old: {
      buildInputs = [ libuv ];
      patchPhase = ''
        sed -i cl-libuv-${old.version}/lib.lisp \
          -e 's|"libuv.so.1"|"${libuv}/lib/libuv.so.1"|'
      '';
    };
    "cl-mysql" = old: {
      patchPhase = ''
        sed -i cl-mysql-${old.version}/system.lisp \
          -e 's|"libmysqlclient"|"${mysql-client}/lib/libmysqlclient"|' \
          -e 's|"libmysqlclient_r"|"${mysql-client}/lib/libmysqlclient_r"|'
      '';
    };
    "cl-opengl" = old: {
      patchPhase = ''
        sed -i cl-opengl-${old.version}/gl/library.lisp \
          -e 's|"libGL.so"|"${libglvnd}/lib/libGL.so"|'
      '';
    };
    "cl-protobufs" = old: { buildInputs = [ protobuf ]; };
    "cl-webkit2" = old: {
      patchPhase = ''
        sed -i cl-webkit-${old.version}/webkit2/webkit2.init.lisp \
          -e 's|"libwebkit2gtk-4.0.so"|"${webkitgtk}/lib/libwebkit2gtk-4.0.so"|'
      '';
    };
    "clsql-postgresql" = old: {
      patchPhase = ''
        sed -i clsql-${old.version}/db-postgresql/postgresql-loader.lisp \
          -e 's|"libpq"|"${postgresql.lib}/lib/libpq"|'
      '';
    };
    "clsql-sqlite3" = old: {
      patchPhase = ''
        sed -i clsql-${old.version}/db-sqlite3/sqlite3-loader.lisp \
          -e 's|"libsqlite3"|"${sqlite.out}/lib/libsqlite3"|'
      '';
    };
    "gsll" = old: {
      buildInputs = [ gsl ];
      patchPhase = ''
        sed -i gsll-quicklisp-eeeda841-git/init/init.lisp \
          -e 's|"libgslcblas.so.0"|"${gsl}/lib/libgslcblas.so.0"|'
        sed -i gsll-quicklisp-eeeda841-git/init/init.lisp \
          -e 's|"libgsl.so"|"${gsl}/lib/libgsl.so"|'
      '';
    };
    "iolib" = old: {
      buildInputs = [ libfixposix ];
      patchPhase = ''
        sed -i iolib-v0.8.4/src/syscalls/ffi-functions-unix.lisp \
          -e 's|"libfixposix"|"${libfixposix}/lib/libfixposix"|'
        cat iolib-v0.8.4/src/syscalls/ffi-functions-unix.lisp
      '';
    };
    "lev" = old: {
      patchPhase = ''
        sed -i lev-${old.version}/src/lev.lisp \
          -e 's|"libev.so"|"${libev}/lib/libev.so"|'
      '';
    };
    "lla" = old: {
      patchPhase = ''
        sed -i lla-${old.version}/src/configuration.lisp \
          -e 's|"libblas.so"|"${openblas}/lib/libblas.so"|' \
          -e 's|"liblapack.so"|"${openblas}/lib/liblapack.so"|'
      '';
    };
    "sqlite" = old: {
      patchPhase = ''
        sed -i cl-sqlite-${old.version}/sqlite-ffi.lisp \
          -e 's|"libsqlite3.so.0"|"${sqlite.out}/lib/libsqlite3.so.0"|'
      '';
    };
    "zeromq" = old: {
      buildInputs = [ zeromq ];
      patchPhase = ''
        sed -i cl-zmq-${old.version}/src/package.lisp \
          -e 's|"libzmq.so.0.0.0"|"${zeromq}/lib/libzmq.so.5.2.4"|'
      '';
    };
    "zmq" = old: {
      buildInputs = [ zeromq ];
      patchPhase = ''
        sed -i lisp-zmq-${old.version}/src/ffi.lisp \
          -e 's|"libzmq"|"${zeromq}/lib/libzmq"|'
      '';
    };
    "zstd" = old: {
      patchPhase = ''
        sed -i cl-zstd-${old.version}/src/libzstd.lisp \
          -e 's|"libzstd.so"|"${zstd.out}/lib/libzstd.so"|'
      '';
    };

    # qt-libs has its own special "find non-Lisp libraries" logic, but it isn't
    # too fundamentally different from the CFFI logic.
    "qt-libs" = old: {
      patchPhase = ''
        sed -i qt-libs-${old.version}/qt4.lisp \
          -e 's|#p"/usr/local/Trolltech/Qt-4.8.7/lib/"|#p"${qt4.out}/lib/"|' \
          -e 's|#p"/usr/local/Trolltech/Qt-4.8.7/plugins/"|#p"${qt4.out}/lib/qt4/plugins/"|'
      '';

      # TODO: fix me later...
      meta.broken = true;
    };

    # Swank has its own build system, so needs custom handling.
    swank = old: {
      patchPhase = ''
        # Swank uses its own non-ASDF loader / build system. This doesn't look
        # at the variables we care about, so we patch it to just hard-code in
        # the output directory for FASLs. (It's able to find itself by virtue
        # of ASDF invoking it.)
        sed -i slime-${old.version}/swank-loader.lisp \
          -e "s|(default-fasl-dir)|#p\"$out/lib/slime-${old.version}/\"|"

        # The aforementioned build system also uses timestamp <= instead of <
        # to determine when files are out of date, breaking Nix by always
        # considering two files of equal (in this case zeroed out) timestamp to
        # be out of date with each other.
        sed -i slime-${old.version}/swank-loader.lisp \
          -e 's/(<= (file-write-date fasl) newest)/(< (file-write-date fasl) newest)/'
      '';
    };

    # cl-unicode seems to be missing a dependency edge?
    # TODO: Investigate this later.
    "cl-unicode" = old: {
      propagatedBuildInputs = old.propagatedBuildInputs
        ++ [ lispPackages.flexi-streams ];
    };
  };
}
