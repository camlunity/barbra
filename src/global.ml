open Common

let version = "0.2"

let brb_conf = "brb.conf"  (* file name without paths *)

let base_dir = Sys.getcwd ()
let dep_dir = base_dir </> "_dep"
let tmp_dir = dep_dir </> "tmp"
let bin_dir = dep_dir </> "bin"
let lib_dir = dep_dir </> "lib"
let share_dir = dep_dir </> "share"
let stublibs_dir = lib_dir </> "stublibs"
let etc_dir = dep_dir </> "etc"
let env_sh = dep_dir </> "env.sh"

let recipe_dir,set_recipe_dir = 
  let ans = ref (Sys.getenv "HOME" </> ".brb" </> "recipes") in
  (fun () -> !ans), ((:=)ans)

let env = [ (`Prepend, "OCAMLPATH", lib_dir)
          ; (`Prepend, "PATH", bin_dir)
          ; (`Set, "OCAMLFIND_DESTDIR", lib_dir)
          ; (`Prepend, "CAML_LD_LIBRARY_PATH", stublibs_dir)
          ; (`Set, "OCAMLFIND_LDCONF", "ignore")

          (* FIXME(superbobry): maybe there's a better way to do this. *)
          ; (`Set, "BRB_BASEDIR", base_dir)
          ; (`Set, "BRB_DEPDIR", dep_dir)
          ] @
          (try [`Set, "MAKE", Sys.getenv "MAKE"] 
           with Not_found -> [`Set, "MAKE", "make"])

(** [create_dirs ()] Create initial directory structure for [brb]. *)
let create_dirs =
  let create_dirs_lazy = lazy (
    Fs_util.make_directories_p [
      base_dir; dep_dir;
      tmp_dir; bin_dir; lib_dir; share_dir; etc_dir;
      stublibs_dir
    ]
  ) in fun () -> Lazy.force create_dirs_lazy

let expand_vars =
  Str.global_substitute
    (Str.regexp "\\$[A-Za-z_]+")
    (fun m ->
      let var = Str.matched_string m in
      match var with
        | "$base_dir" -> base_dir
        | "$recipe_dir" -> recipe_dir ()
        | "$dep_dir" -> dep_dir
        | "$lib_dir" -> lib_dir
        | "$bin_dir" -> bin_dir
        | _ -> getenv (Str.string_after var 1) )














