open Common

let version = "2"

let brb_conf = "brb.conf"  (* file name without paths *)

let base_dir = Sys.getcwd ()
let dep_dir = base_dir </> "_dep"
let tmp_dir = dep_dir </> "tmp"
let bin_dir = dep_dir </> "bin"
let lib_dir = dep_dir </> "lib"
let stublibs_dir = lib_dir </> "stublibs"
let etc_dir = dep_dir </> "etc"
let env_sh = dep_dir </> "env.sh"


(** [create_dirs ()] Create initial directory structure for [brb]. *)
let create_dirs =
  let create_dirs_lazy = lazy (
    Fs_util.make_directories_p [
      base_dir; dep_dir; tmp_dir; bin_dir; lib_dir; etc_dir; stublibs_dir
    ]
  ) in fun () -> Lazy.force create_dirs_lazy
