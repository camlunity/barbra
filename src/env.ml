open Common
open Types
open Printf
open WithM

module G = Global

let (>>=) = Res.(>>=)


module WithCombs = struct
  open WithM
  open Res
  open WithRes

  (* Note(gds): unset variables will be restored to "". *)
  let with_env =
    { cons = (fun (env_name, new_val) ->
      let old_val = getenv env_name in
      let () = Unix.putenv env_name new_val in
        return (env_name, old_val)
      )
    ; fin = (fun (env_name, old_val) ->
        let () = Unix.putenv env_name old_val in
        return ()
      )
    }

  let with_env_prepended =
    premap
      (fun (name, what_to_prepend) ->
        let new_var = match getenv name with
          | "" -> what_to_prepend
          | old_path -> Printf.sprintf "%s:%s" what_to_prepend old_path
        in (name, new_var)
      )
      with_env
end


open WithCombs


let withres_env =
  WithRes.sequence
    { WithRes.cons = begin function
        | (`Prepend, n, v) ->
            with_env_prepended.WithRes.cons (n, v) >>= fun r ->
            Res.return (`Prepend, r)
        | (`Set, n, v) ->
            with_env.WithRes.cons (n, v) >>= fun r ->
            Res.return (`Set, r)
      end
    ; fin = begin function
        | (`Prepend, old_env) -> with_env_prepended.WithRes.fin old_env
        | (`Set, old_env) -> with_env.WithRes.fin old_env
      end
    }

let do_write_env fn =
  Filew.with_file_out_bin fn & fun outch ->
  List.iter ~f:(
   let set n v = fprintf outch "export %s=\"%s\"\n" n v in
   function
     | (`Set, n, v) -> set n v
     | (`Prepend, n, v) ->
         ( fprintf outch "test -z \"$%s\" || %s=\":$%s\"\n" n n n
         ; set n (sprintf "%s$%s" v n)
         )
    )
    G.env


(* Public API. *)

let write_env =
  let lazy_write_env = lazy (do_write_env G.env_sh) in
  fun () -> Lazy.force lazy_write_env

let with_env f =
  withres_env G.env (fun _old_env -> f())

let exec_with_env cmd = with_env (fun () -> exec cmd)
