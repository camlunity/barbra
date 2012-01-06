Damn Simple Package Manager for OCaml
=====================================

`barbra` is beta software! incomplete specification *in russian* can be
found [here](https://docs.google.com/document/d/1dxbuu3RP3NCxMI54YFRtnwFUOTrIj-EWmBdwy32a0CI/edit)

Basics
------

This project is named `barbra`, executable file is `brb`, project's
configuration file is `brb.conf`.


Goals
-----

* Keep all project dependencies in a separate config file -- `brb.conf`
  (similar to [rebar.config](http://github.com/basho/rebar), popular
  in Erlang community)
* Fetch dependencies easily from anywhere: archive, vcs, local folder, etc.
* Fetch, build and install dependencies with a single command.

Why not ...?
------------

### oasis-db
1. by its design it requires uploading the tarball to central server,
   it's not very flexible.  The alternative is to use known locations
   of packages' sources.
2. don't know what to do with private projects -- should we setup
   our own oasis-db server?
3. too heavy for simple tasks.
4. it's *beta* two years and it's not ready to use now (however
   the author of oasis-db uses it).
5. the need to mark projects as stable/... -- does anybody use it?
   it seems to be an additional bureaucracy.

### overbld
1. it's not flexible at all, it make "monolithic collection of ocaml
   and libraries", because it's author was too lazy to make more
   flexible software -- overbld is written in bash, and it's hard
   to do something good in bash.

### godi
1. doesn't work on ocaml/msvc.
2. works on linux, but has problems on windows generally.
3. requires writing godi-specific files in every project.
4. haven't gained popularity, too few people are writing godi-files
   now, oasis is the trend.

**Note**: of course, we will have similar problems with project's
specific files, but:

* in simple cases one will not be required to write any
files if all dependencies are available with currently-available
ocamlfind;
* one should not write config-file for every project,
it will be enough to write one config for the main project you are
building.


Definitions
-----------

Documentation uses some terms with more precise meaning than
usually, so we'll state these terms' definitions.

1. **package manager** -- a progam described in this documentation,
   whichaims to solve problems described in **Goal** (however,
   for now it's the "dependencies' downloader and installer", not
   a fair package manager).
2. **project** -- set of programs, libraries and utilities, stored in
   some specific directory.  Project uses *package manager* for compilation
   and installation.
3. **package** -- set of libraries and utilities that use some standard
   ways to compile and install, for example, that builds with
   `./configure && make && make install` and installs with `ocamlfind`.
4. **project configuration** -- file `brb.conf`, which lists all project
   dependencies, namely: where to get them (url of tarball, url of VCS,
   path to local files, path to bundled dependencies).
   *Note*: in some future the "project configuration" may contain
   inter-package dependencies and directives like "always install
   fresh-downloaded packages to local environment", "trust default
   ocamlfind's packages" or "install packages to default ocamlfind's
   destination"
5. **bundle** -- archive that contains the project's sources with
   sources of its dependencies (according to brb.conf), unpacked, ready
   for easy compilation and installation (with some shell script, for
   example), without any additional requirements (except ocaml + findlib
   which are required anyway).  Dependencies are stored unpacked in
   archive's directories, so tar/gunzip/bunzip2 are not needed to use
   the bundle.


Documentation on version 1.0
----------------------------


### Targets


`brb` version 1.0 can only download and install dependencies that are
written down in project configuration file, sequentially, in the order
of appearance in project config.  All other dependencies will be resolved
via ocamlfind.

It means that environment variables (`OCAMLPATH` and some others) will
contain prepended/overwritten paths for the purposes of packages' compilation
and installation.


### File system layout

Any project that uses brb will have these files and directories
(some of them are temporary).

```
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
```

Environment variable `OCAMLPATH` (and some others) will be modified
to allow the project to build (packages and the project itself).

The contents of `_dep` directory will be removed before the build
and after the successful build.  Otherwise the directory contents will
be kept as is, to allow to diagnose the build problems.


### Project's configuration

Version 1 configuration file simply lists required packages' names
along with source location. Config syntax is pretty straightforward:

* Any config's line can be the comment (matching regexp /^\s*#/).
* The first uncommented line must be:

    version 1

  This allows developers to modify the format of configuration file later.
* **One** dependency per line! the format is:

    dep  <package_name>  <retrieving_method>  <url>

  It's assumed that every field but last does not contain whitespaces,
  and whitespace delimit the fields. The last field, *url*, may contain
  whitespace inside it, but not before or after it. See below for
  available *retrieving_method*s.
* Dependencies are processed sequentially one-by-one.
* Duplicating packages are not allowed.

#### Retrieving methods

```
| Method          | Description                                                |
|-----------------+------------------------------------------------------------|
| remote-tar      | Package will be fetched with curl or wget and then         |
| remote-tar-gz   | unpacked with an appropriate archiver.                     |
| remote-tar-bz2  |                                                            |
|-----------------+------------------------------------------------------------|
| local-tar       | Package will be unpacked from local file system (*url*     |
| local-tar-gz    | is absolute path to the archive).                          |
| local-tar-bz2   |                                                            |
|-----------------+------------------------------------------------------------|
| local-dir       | Package will be copied from local file system, from the    |
|                 | directory, specified in *url*.                             |
|-----------------+------------------------------------------------------------|
| bundled-dir     | Package's sources are placed locally, within the project   |
| bundled-tar*    | itself, this might be usefull for making *bundles*.        |
|-----------------+------------------------------------------------------------|
| bzr, cvs, darcs | Packaged will be cloned or checked out from the repository |
| git, hg, svn    | by its *url*; which might as well point to he local        |
|                 | repository.                                                |
```

### brb command line

```
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
```


### Example
-----

```
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
```

### Hints

Version 1.0 is very limited, the real world is much more complex. We
are trying to integrate features in barbra, but it's impossible without
deep thinking.

But sometimes one needs to build project, that can be built much
harder than `configure && make all && make install`.  For example,
some projects build only bytecode libraries on `make all` (and
we need to `make opt` to compile native code libraries), some projects
require specific `./configure` flags.

The current workarounds are ugly, but they work in simple cases
(not in general, not for "making patches for upstream").

1. If you need to modify configure or makefile invocation, first
   copy or clone the sources to some private directory (for example,
   take a look at `dep json-wheel local-dir ../json-wheel-1.0.6` above),
   then modify the sources to make it work.
   In the text below we assume you have copied sources to local private directory.

2. If you need to pass additional options to `./configure`,
   rename configure script, then write your own ./configure like this:

```bash
#!/bin/sh
. ./configure-orig --disable-libev $*
```

3. If you need to build Makefile's targets other than `"all"`,
   rename `"all"` target to `"all_old"` and write new target `"all"`:

```makefile
all : all_old opt
```
