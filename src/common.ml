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


let nul_redirects = lazy
  (let open UnixLabels in
   let opengen ~mode n = openfile n ~mode ~perm:0o777 in
   let openout n = opengen n ~mode:[O_WRONLY] in
   let openin n = opengen n ~mode:[O_RDONLY] in
   let n = Filew.filename_NUL in
   let nul_out = openout n in
   (openin n, nul_out, nul_out, " (redirecting to " ^ n ^ ")")
  )

let std_redirects = lazy
  (let open Unix in
   (stdin, stdout, stderr, "")
  )


(** [exec_exitcode args] Executes a given command in a separate process;
    a command is given a a list of arguments, for example:

    let _ : (int, exn) Res.res = exec_exitcode ["sh"; "-c"; "./configure"];;

    The returned value is the exit code of the process.
*)
let exec_exitcode ?(redirects=`Std) args = Res.catch_exn (fun () ->
  let open UnixLabels in match args with
    | [] -> failwith "can't execute empty command!"
    | (prog :: _) as args ->
      let cmd = command_text_of_args args in
      let (stdin, stdout, stderr, redir_msg) = Lazy.force &
        match redirects with
        | `Std -> std_redirects
        | `Nul -> nul_redirects
      in

      let () = Log.info "Running command %S%s" cmd redir_msg in
      (* ^^^ logging about future actions must be done before making them! *)

      let () = Log.debug "Running command's argv: [%s]"
        (String.concat " ; " &
           List.map (Printf.sprintf "%S") args)
      in

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

let exec_exn cmd = Res.exn_res (exec cmd)
