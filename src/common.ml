include ExtString
include Cd_Ops

module Stream = Am_Stream.Stream

let failwith fmt = Printf.ksprintf failwith fmt

let identity x = x

let (</>) = Filename.concat

let command_text_of_args args =
  if args = []
  then "<empty command>"
  else String.concat " " args


(** [exec_exitcode args] Executes a given command in a separate process;
    a command is given a a list of arguments, for example:

    let _ : (int, exn) Res.res = exec_exitcode ["sh"; "-c"; "./configure"];;

    The returned value is the exit code of the process.
*)
let exec_exitcode args = Res.catch_exn (fun () ->
  let open UnixLabels in match args with
    | [] -> failwith "can't execute empty command!"
    | (prog :: _) as args ->
      let cmd = command_text_of_args args in
      let () = Log.info "Running command %S" cmd in
      (* ^^^ logging about future actions must be done before making them! *)

      let () = Log.debug "Running command's argv: [%s]" &
        String.concat " ; " &
        List.map (Printf.sprintf "%S") args in

      let pid = create_process
        ~prog
        ~args:(Array.of_list args)
        ~stdin ~stdout ~stderr in
      begin
        match waitpid ~mode:[] pid with
          | (pid', _) when pid' <> pid -> assert false
          | (_, WEXITED code) ->
            Res.return code
          | (_, WSIGNALED signal) ->
            Log.error "Command %S was killed by signal %i" cmd signal
          | (_, WSTOPPED _) ->
            assert false  (* we are not waiting for stopped processes *)
      end
)


(** [exec args] Executes a given command in a separate process;
    a command is given a a list of arguments, for example:

    let _ : (unit, exn) Res.res = exec ["sh"; "-c"; "./configure"];;
*)
let exec args =
  let open Res in
  exec_exitcode args >>= fun code ->
  catch_exn
    (fun () ->
       let cmd = command_text_of_args args in
       match code with
       | 0 -> Res.return ()
       | 127 ->
           Log.error "Command %S not found \
             (terminated with exit code %i)" cmd code
       | code ->
           Log.error "Command %S terminated with exit code %i" cmd code
    )
