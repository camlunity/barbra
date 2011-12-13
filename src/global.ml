open Common

let version = 1

let brb_conf = "brb.conf"  (* просто имя файла без путей *)

let base_dir = Sys.getcwd ()
let dep_dir = base_dir </> "_dep"
let tmp_dir = dep_dir </> "tmp"
let bin_dir = dep_dir </> "bin"
let lib_dir = dep_dir </> "lib"
let etc_dir = dep_dir </> "etc"
