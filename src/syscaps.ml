open Common
open Res


(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
let ensure cmd =
  Sys.command (Printf.sprintf "sh -c 'which %s &> /dev/null'" cmd) = 0


let rec first = function
  | [] -> fail ()
  | (hcap, hval) :: t ->
      begin match hcap with
        | `Executable n ->
            if ensure n
            then return hval
            else first t
      end
