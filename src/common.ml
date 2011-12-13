(* значения, важные во всём проекте *)

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

include Printf

let dbg fmt = ksprintf (fun s -> eprintf "DBG: %s\n%!" s) fmt

let (</>) = Filename.concat

let command fmt = Printf.ksprintf Res.Sys.command_ok fmt
