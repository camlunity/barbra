
open Printf

open Types
open Common


let cfg = "dep erm_xml Git git://github.com/ermine/xml.git
dep amall Hg https://bitbucket.org/gds/amall
dep ocaml-gnuplot Bzr bzr://ocaml-gnuplot.bzr.sourceforge.net/bzrroot/ocaml-gnuplot
dep ocaml-extlib Svn http://ocaml-extlib.googlecode.com/svn/trunk/
dep secret-project local
dep oasis http-tar-gz https://forge.ocamlcore.org/frs/download.php/626/oasis-0.2.1~alpha1.tar.gz
dep not-so-secret-project fs-tar ~/nssp.tar
dep work-project fs-src ~/work/project"


let cfg_res = [
  ("erm_xml", VCS ("git://github.com/ermine/xml.git", Git));
  ("amall", VCS ("https://bitbucket.org/gds/amall", Hg));
  ("ocaml-gnuplot", VCS ("bzr://ocaml-gnuplot.bzr.sourceforge.net/bzrroot/ocaml-gnuplot", Bzr));
  ("ocaml-extlib", VCS ("http://ocaml-extlib.googlecode.com/svn/trunk/", Svn));
  ("secret-project", Local);
  ("oasis", HttpArchive ("https://forge.ocamlcore.org/frs/download.php/626/oasis-0.2.1~alpha1.tar.gz", TarGz));
  ("not-so-secret-project", FsArchive ("~/nssp.tar", Tar));
  ("work-project", FsSrc "~/work/project")
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
