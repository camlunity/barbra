(* значения, важные во всём проекте *)

let base_dir = "_dep"

(***************************)

include ExtString

let failwith fmt = Printf.ksprintf failwith fmt

(* resource management operations *)
let try_finally action finally =
  try
    let result = action () in
      finally ();
      result;
  with x -> finally (); raise x

let with_resource resource action post =
  try_finally (fun () -> action resource) (fun () -> post resource)

let with_file_in filename action =
  with_resource (open_in filename) action close_in

let identity x = x

let list_all lst =
(*
  List.fold_left (fun acc el -> acc && el) true lst

  more efficiently, stops on first "false":
*)
  List.for_all identity lst

include Cd_Ops
module Stream = Am_Stream.Stream


(** [makedirs mode path] recursively creates a given path, in the way
    'mkdir -p' does it. *)
let makedirs ?(mode=0o755) path =
  ignore & List.fold_left
    (fun base chunk ->
      let dir = Filename.concat base chunk in
      if not (Sys.file_exists dir) then
        Unix.mkdir dir mode;

      dir)
    ""
    (String.nsplit path Filename.dir_sep)

include Printf

let dbg fmt = ksprintf (fun s -> eprintf "DBG: %s\n%!" s) fmt
