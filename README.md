Damn Simple Package Manager for OCaml
=====================================

Specification (work in progress) :

  https://docs.google.com/document/d/1dxbuu3RP3NCxMI54YFRtnwFUOTrIj-EWmBdwy32a0CI/edit

How to use :

  FIXME


(* OASIS_START *)
(* DO NOT EDIT (digest: 0334a6ea39277bb2ed53e632eff63736) *)
This is the README file for the barbra distribution.

Damn Simple Package Manager

See the files INSTALL.txt for building and installation instructions. 


(* OASIS_STOP *)


Documentation


Name

  This project is named "barbra", executable file is "brb", project's
configuration file is "brb.conf".

Global targets

  brb will download/get the dependencies and install them.  brb's work
is guided by local project's config (similar to rebar's "rebar.config")
and by brb's invocation options.  It is supposed to automatize the usually
manual steps:
1. downloading source code : curl || git || svn
2. unpacking : tar -xz || tar -xj || 7z x
3. recursive search of dependencies
4. building : ./configure && make || ocaml setup.ml -build ||
   ./configure && omake
5. installation : make install || omake install || ocaml setup.ml -install


Why not <alternative>?

1. oasis-db
   1. by its design it requires uploading the tarball to central server,
      it's not very flexible.  The alternative is to use known locations
      of packages' sources.
   2. don't know what to do with private projects -- should we setup
      our own oasis-db server?
   3. too heavy for simple tasks.
   4. it's "beta" two years and it's not ready to use now (however
      the author of oasis-db uses it).
   5. the need to mark projects as stable/... -- does anybody use it?
      it seems to be an additional bureaucracy.
   6. can't install software from VCS for now (2011-12-29).
2. overbld
   1. it's not flexible at all, it make "monolithic collection of ocaml
      and libraries", because it's author was too lazy to make more
      flexible software -- overbld is written in bash, and it's hard
      to do something good in bash.
3. godi
   1. doesn't work on ocaml/msvc.
   2. works on linux, but has problems on windows generally.
   3. requires writing godi-specific files in every project.
   4. haven't gained popularity, too few people are writing godi-files
      now, oasis is the trend.
   (of course, we will have similar problems with project's specific
   files, but: 1. in simple cases one will not be required to write any
   files if all dependencies are available with currently-available
   ocamlfind, 2. one should not write config-file for every project,
   it will be enough to write one config for the main project you are
   building.)



Definitions

  Documentation uses some terms with more precise meaning than
usually, so we'll state these terms' definitions.

1. "package manager" -- progam described in this documentation, which
aims to solve problems described in chapter "Global targets".  (however,
for now it's the "dependencies' downloader and installer", not a fair
package manager.)
2. "project" -- set of programs, libraries and utilities, stored in
some specific directory.  Project uses "package manager" for compilation
and installation.
3. "package" -- set of libraries and utilities that use some standard
ways to compile and install, for example, that builds with
"./configure && make && make install" and installs with ocamlfind.
4. "project configuration" -- file "brb.conf" where user describes what
dependencies the project requires, where to get them (url of tarball,
url of VCS, path to local files, path to bundled dependencies).
(in some future the "project configuration" may contain inter-package
dependencies and directives like "always install fresh-downloaded packages
to local environment", "trust default ocamlfind's packages" or
"install packages to default ocamlfind's destination")
5. "bundle" -- archive that contains the project's sources with sources
of its dependencies (according to brb.conf), unpacked, ready for easy
compilation and installation (with some shell script, for example),
without any additional requirements (except ocaml+findlib which are
required anyway).  Dependencies are stored unpacked in archive's
directories, so tar/gunzip/bunzip2 are not needed to use the bundle.


Documentation on version 1.0


Targets of version 1.0


  brb version 1.0 can only download and install dependencies that are
written down in project configuration file, sequentially, in the order
of appearance in project config.  All other dependencies will be resolved
via ocamlfind.
  It means that environment variables (OCAMLPATH and some others) will
contain prepended/overwritten paths for the purposes of packages' compilation
and installation.


File system layout

  Any project that uses brb will have these files and directories
(some of them are temporary).

/brb.conf               --  project configuration
/_dep/                  --  directory for downloading, compiling and
                            installing packages
/_dep/tmp/              --  directory for temporary files (for example,
                            downloaded .tar.gz)
/_dep/tmp/<dep_name>/   --  directory for sources of package <dep_name>,
                            used for compilation of <dep_name>
/_dep/{bin,etc,lib}/    --  directories where the package will be installed
                            in case of "local installation" (version 1.0
                            allows only local installations).
/_dep/env.sh            --  shell script that sets/prepends local pathes
                            to environment variable, when run as
                            ". _dep/env.sh" or "source _dep/env.sh"


  Environment variable OCAMLPATH (and some others) will be modified
to allow the project to build (packages and the project itself).

  The contents of "_dep" directory will be removed before the build
and after the successful build.  Otherwise the directory contents will
be kept as is, to allow to diagnose the build problems.


Project's configuration


  Project's configuration of brb 1.x states which packages brb needs
to install and where it will get them.  Version 1 is very dumb, so
the configuration file is very simple.
  Any config's line can be the comment (matching regexp /^\s*#/).
  The first uncommented line must be

"version 1"

  , it allows developers to modify the format of configuration file later.

  Every dependency occupies exactly one line of config, the format is:

"dep  <package_name>  <retrieving_method>  <url>"

  It's assumed that every field but last does not contain whitespaces,
and whitespaces delimit the fields.
  The last field, "url", can contain spaces inside it, but not before/after it.
(for example, it may be useful for specification of paths with spaces).

  "retrieving_method" determines how brb will get dependency:
1. remote-tar{,-{gz,bz2}}  --  package will be downloaded with curl/wget
   and unpacked with tar -x{,{z,j}}
2. local-tar{,-{gz,bz2}} -- package will be unpacked from local file system,
   the "url" is the path to .tar{,.{gz,bz2}} file
3. local-dir -- package will be copied from local file system, from the
   directory specified in "url", that should contain the project's source
   tree.
4. bundled-{dir,tar{,-{gz,bz2}}} -- package's sources are placed locally,
   withing the project itself, it will be useful for making "bundles".
5. {bzr,cvs,darcs,git,hg,svn} -- package will be cloned / checked out from
   the repository by its "url" (it can be local repository too, without
   restrictions).  The corresponding VCS utility will be used to get sources:
   1. hg clone url destdir
   2. git clone --depth=1 url destdir
   3. svn co url destdir
   4. cvs checkout
   5. darcs get --lazy url destdir
   6. ... etc


  Dependencies are processed sequentially.  It's how we state the
interpackage dependencies for now, in version 1.

  Duplicating packages are not allowed.


brb command line

$ brb <command or option>:
  help | --help         output this help
  version | --version   output version
  build                 build the project in the current directory,
                        assuming that "_dep" either doesn't exist or
                        contains built dependencies
  clean                 remove built dependencies ("_dep" directory)
  rebuild               rebuilds dependencies and the project
  run cmd arg1 .. argN  run "cmd arg1 .. argN" with environment that
                        allows ocamlfind use libraries installed in
                        "_dep" and allows to run programs installed in
                        "_dep/bin".  The same effect as with shell
                        command "( . _dep/env.sh ; cmd arg1 .. argN)"
                        when "_dep/env.sh" does exist
  build-deps            build project's dependencies, assuming that
                        "_dep" either doesn't exist or contains built
                        dependencies
  rebuild-deps          rebuild project's dependencies



Practical experience

  It's known that brb has built the project with the following configuration
file (lines are wrapped manually):

    $ cat brb.conf
    version 1

    dep ounit remote-tar-gz
      http://forge.ocamlcore.org/frs/download.php/495/ounit-1.1.0.tar.gz

    dep pcre-ocaml remote-tar-bz2
      http://hg.ocaml.info/release/pcre-ocaml/archive/release-6.2.3.tar.bz2
    dep ocamlnet local-dir ../ocamlnet/work
    dep json-wheel local-dir ../json-wheel-1.0.6
    dep json-static remote-tar-bz2
      http://martin.jambon.free.fr/json-static-0.9.8.tar.bz2

    dep lwt local-dir ../lwt-2.3.2

    dep ocaml-substrings hg ssh://some-dev-server//repo/ocaml-substrings
    dep ocaml_monad_io hg ssh://some-dev-server//repo/ocaml_monad_io
    dep ocaml-iteratees hg ssh://some-dev-server//repo/ocaml-iteratees
    dep dumbstreaming hg ssh://some-dev-server//repo/dumbstreaming

    dep cadastr hg ssh://some-dev-server//repo/cadastr
    dep parvel hg ssh://some-dev-server//repo/parvel#1bc1c224051c

    dep postgresql hg http://hg.ocaml.info/release/postgresql-ocaml
    dep amall hg ssh://some-dev-server//repo/amall

  So, it is usable and useful for some of developers.


Practical hints

  The version 1.0 is very limited, the real world is much more complex.
We are trying to integrate features in barbra, but it's impossible before
deep thinking.

  But sometimes one needs to build project, that can be built much
harder than "configure + make all + make install".  For example, some
projects build only bytecode libraries on "make all" (and we need to
"make opt" to compile native code libraries), some projects require
some specific ./configure options.

  The current workarounds are ugly, but they work in simple cases
(not in general, not for "making patches for upstream").

1. If you need to modify configure or makefile invocation, first
copy/clone the sources to some private directory (for example,
take a look at "dep json-wheel local-dir ../json-wheel-1.0.6" above),
then modify the sources to make it work.
   In the text below we assume you have copied sources to local
private directory.

2. If you need to pass additional options to ./configure,
rename configure script, then write your own ./configure like this:

    #!/bin/sh
    . ./configure-orig --disable-libev $*

3. If you need to build makefile's targets other than "all",
rename "all" target to "all_old" and write new target "all":

    all : all_old opt
