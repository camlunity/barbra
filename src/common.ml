include ExtHashtbl
include ExtString
include Cd_Ops

module StringSet = Set.Make(String)
module StringMap = Map.Make(String)

module List = struct
  include ExtList.List
  include ListLabels
end

let failwithf fmt = Printf.ksprintf failwith fmt

let (</>) = Filename.concat

let getenv ?(default="") env_name =
  try Unix.getenv env_name with Not_found -> default


module Subprocess = struct
  open UnixLabels

  let command_text_of_args = function
    | []   -> "<empty command>"
    | args -> String.concat " " args

  let null_redirects = lazy begin
    let null = Filew.filename_NUL in
    let null_in  = openfile ~perm:0o777 ~mode:[O_RDONLY] null in
    let null_out = openfile ~perm:0o777 ~mode:[O_WRONLY] null in
    (null_in, null_out, null_out, " (redirecting to " ^ null ^ ")")
  end

  let std_redirects = lazy begin
    (Unix.stdin, Unix.stdout, Unix.stderr, "")
  end

  let exec_exitcode ?(silent=false) = function
    | [] -> failwith "can't execute empty command!"
    | (prog :: _) as args ->
      let cmd = command_text_of_args args in
      let (stdin, stdout, stderr, redirect_msg) =
        Lazy.force & match (silent, !Log.verbosity) with
          (* Note(superbobry): command output is displayed only on
             [`Info] level! *)
          | (false, 2) -> std_redirects
          | (_, _) -> null_redirects
      in

      Log.info "Running command %S%s" cmd redirect_msg;

      let pid = create_process
        ~prog
        ~args:(Array.of_list args)
        ~stdin ~stdout ~stderr
      in match waitpid ~mode:[] pid with
        | (pid', _) when pid' <> pid -> assert false
        | (_, WEXITED code) -> code
        | (_, WSIGNALED signal) ->
          Log.error "Command %S was killed by signal %i" cmd signal
        | (_, WSTOPPED _) ->
          assert false  (* we are not waiting for stopped processes *)

  let exec args =
    let cmd = command_text_of_args args in
    match exec_exitcode args with
      | 0 -> ()
      | code when code = 127 ->
        Log.error
          "Command %S not found (terminated with exit code %i)" cmd code
      | code ->
        Log.error "Command %S terminated with exit code %i" cmd code
end

let exec = Res.wrap1 Subprocess.exec
let exec_exn = Subprocess.exec
let exec_exitcode ?(silent=false) args =
  Res.res_exn (fun () -> Subprocess.exec_exitcode ~silent args)
