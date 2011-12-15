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

let (</>) = Filename.concat

(** [exec args] Executes a given command in a separate process;
    a command is given a a list of arguments, for example:

    let () = exec ["sh"; "-c"; "./configure"];;
*)
let exec args = Res.catch_exn (fun () ->
  let open UnixLabels in match args with
    | [] -> failwith "can't execute empty command!"
    | (prog :: _) as args ->
      let pid = create_process
        ~prog
        ~args:(Array.of_list args)
        ~stdin ~stdout ~stderr
      and cmd = String.concat " " args in
      begin
        Log.info "Running command %S" cmd;

        match waitpid ~mode:[] pid with
          | (pid', _) when pid' <> pid -> assert false
          | (_, WEXITED code) ->
            if code <> 0 then
              Log.error "Command %S terminated with exit code %i" cmd code
            else Res.return ()
          | (_, WSIGNALED signal) ->
            Log.error "Command %S was killed by signal %i" cmd signal
          | (_, WSTOPPED _) ->
            assert false  (* we are not waiting for stopped processes *)
      end
)

let exec_exn : string list -> unit = Res.exn_res %< exec

let mkdir_p path = exec ["mkdir"; "-p"; path]
