```
  _                _
 | |              | |
 | |__   __ _ _ __| |__  _ __ __ _
 | '_ \ / _` | '__| '_ \| '__/ _` |
 | |_) | (_| | |  | |_) | | | (_| |
 |_.__/ \__,_|_|  |_.__/|_|  \__,_|

 a simple package manager for OCaml
```

## What is barbra?

`barbra` is a simple command line tool, which knows how to fetch, build
and install you project's dependencies.

**Note**: `barbra` was inspired by [rebar](https://github.com/basho/rebar)
-- a similar project, written by Erlang community.


## How do I use it?

`barbra` uses a single file -- `brb.conf`, which lists all external
tools and libraries your project depends upon. So step one is
to create `brb.conf`. Here's an example of a simple `brb.conf`
file:

```ocaml
Version 2

Dep lwt remote "http://ocsigen.org/download/lwt-2.3.2.tar.gz"
    Flag "--disable-extra"
    Flag "--disable-preemptive"
    Make "build"
```

* The first non-empty line should **always** be version spec, which
  tells `barbra` that this config is up to date with `Version 2`
  syntax.
* All config keywords are case insensitive, so we could as well use
  `versiOn 2` for the first line.
* Each dependency starts with a `Dep` block, which takes three
  arguments:
  * package name: *lwt* (in the example above)
  * source type: *remote*, full table of suppored *source types*
    is given below
  * source location: a **quoted** URI of the package you want
    installed
* You can also specify extra `configure` flags or `make` targets.
* Dependencies will be built in the same order they appear in
  `brb.conf` -- this *may* change in the future.

Once you're done with `brb.conf`, run `brb rebuild` from the top
directory of you project -- this will fetch all listed dependencies,
build them and then build your project in an isolated `barbra`
environment with installed dependencies:

```bash
$ brb build
I: Fetching http://ocsigen.org/download/lwt-2.3.2.tar.gz to ...
```

## Supported source types

    | Type            | Description                                                 |
    |-----------------+-------------------------------------------------------------|
    | remote          | Package will be fetched with curl or wget and then          |
    |                 | unpacked with an appropriate archiver.                      |
    |                 |                                                             |
    |-----------------+-------------------------------------------------------------|
    | local           | Package will be unpacked from local file system (*location* |
    |                 | is absolute path to the archive).                           |
    |-----------------+-------------------------------------------------------------|
    | local-dir       | Package will be copied from local file system, from the     |
    |                 | directory, specified in *location*.                         |
    |-----------------+-------------------------------------------------------------|
    | bzr, cvs, darcs | Packaged will be cloned or checked out from the repository  |
    | git, hg, svn    | by its *location*; which might as well point to he local    |
    |                 | repository.                                                 |

## More?

`barbra` is currently under active development and this 'README' is
the only documentation up to date; however, you can try:

* reading example
  [brb.conf](https://github.com/camlunity/barbra/blob/master/brb.conf)
  or the output of `brb --help`,
* asking for help on the IRC channel `#ocaml` on Freenode (nickname:
  `superbobry`) or, if you speak Russian, on `ocaml@conference.jabber.ru`.
