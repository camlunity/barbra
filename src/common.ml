include ExtString
include Cd_Ops

module Stream = Am_Stream.Stream

let failwith fmt = Printf.ksprintf failwith fmt

let identity x = x

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
