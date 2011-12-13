(* values that are used in the project *)

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

(*
let command fmt = Printf.ksprintf Res.Sys.command_ok fmt
*)

(* differs from Unix.create_process!
   usage example:
     exec [ "sh" ; "-c" ; "./configure" ]
*)
let exec args_list : (unit, exn) Res.res =
  Res.catch_exn
    (fun () ->
       let open Unix in
       if args_list = []
       then failwith "error executing empty command"
       else
       let args = Array.of_list args_list in
       let prog = args.(0) in
       let fail reason = failwith
           "error executing [%s]: %s"
           (String.concat "; " & List.map (sprintf "%S") args_list)
           reason
       in
       let pid = create_process prog args stdin stdout stderr in
       let (pid', st) = waitpid [] pid in
       let () = assert (pid = pid') in
       begin match st with
         | WEXITED code ->
             if code <> 0
             then fail & sprintf "exit code %i" code
             else Res.return ()
         | WSIGNALED s ->
             fail & sprintf "killed by signal %i" s
         | WSTOPPED _ ->
             assert false  (* we are not waiting for stopped processes *)
       end
    )

let exec_exn : string list -> unit = Res.exn_res %< exec

let mkdir_p path = exec ["mkdir"; "-p"; path]
