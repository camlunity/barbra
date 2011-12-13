open Common

let version = 1

let brb_conf = "brb.conf"  (* просто имя файла без путей *)

let base_dir = Sys.getcwd ()
let dep_dir = base_dir </> "_dep"
let tmp_dir = dep_dir </> "tmp"
let bin_dir = dep_dir </> "bin"
let lib_dir = dep_dir </> "lib"
let stublibs_dir = lib_dir </> "stublibs"
let etc_dir = dep_dir </> "etc"


let lazy_dirs_creation = lazy
  (
    List.iter (fun p -> Res.exn_res & mkdir_p p) [
      base_dir; dep_dir; tmp_dir; bin_dir; lib_dir; etc_dir; stublibs_dir
    ]
  )

let create_dirs () = Lazy.force lazy_dirs_creation
