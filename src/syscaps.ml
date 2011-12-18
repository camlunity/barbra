open Common
open Res


(** [ensure cmd opt] Returns [true] if a given [cmd] is available
    on the host system and [false] otherwise.
    The existence of [cmd] is checked by executing process [cmd]
    with single option [opt] (for example, it can be "--version" option),
    exit code "0" is the sign of [cmd] is present. *)
let ensure cmd opt =
  127 <> Res.exn_res (exec_exitcode ~redirects:`Nul [cmd; opt])


let rec first = function
  | [] -> fail ()
  | (hcap, hval) :: t ->
      begin match hcap with
        | `Executable (n, opt) ->
            if ensure n opt
            then return hval
            else first t
      end
