
open Printf

open Types
open Common


let cfg = "version 1

dep erm_xml Git git://github.com/ermine/xml.git
dep amall Hg https://bitbucket.org/gds/amall
dep ocaml-gnuplot Bzr bzr://ocaml-gnuplot.bzr.sourceforge.net/bzrroot/ocaml-gnuplot
dep ocaml-extlib Svn http://ocaml-extlib.googlecode.com/svn/trunk/
dep oasis http-tar-gz https://forge.ocamlcore.org/frs/download.php/626/oasis-0.2.1~alpha1.tar.gz
dep not-so-secret-project tar ~/nssp.tar"

let cfg_res = [
  ("erm_xml", VCS (Git, "git://github.com/ermine/xml.git"));
  ("amall", VCS (Hg, "https://bitbucket.org/gds/amall"));
  ("ocaml-gnuplot", VCS (Bzr, "bzr://ocaml-gnuplot.bzr.sourceforge.net/bzrroot/ocaml-gnuplot"));
  ("ocaml-extlib", VCS (SVN, "http://ocaml-extlib.googlecode.com/svn/trunk/"));
  ("oasis", Remote (`TarGz, "https://forge.ocamlcore.org/frs/download.php/626/oasis-0.2.1~alpha1.tar.gz"));
  ("secret-project", Local (`Directory, "~/work/project"));
  ("not-so-secret-project", Local (`TarGz, "~/nssp.tar"));
]

let test_parse_lines () =
  let config = Config.parse_string cfg in
  cfg_res = config


let tests = [
  test_parse_lines
]


exception TestFailed
let () =
  if list_all (List.map (fun func -> func ()) tests)
  then print_endline "Test passed"
  else raise TestFailed
