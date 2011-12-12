open Common
open Types
open Global


module WithCombs = struct
  open WithM
  open Res
  open WithRes

(* variable that was not set will be restored to "". *)
let with_env =
    { cons = (fun (env_name, new_val) ->
        let old_val =
          try Unix.getenv env_name with Not_found -> ""
        in
        let () = Unix.putenv env_name new_val in
        return (env_name, old_val)
      )
    ; fin = (fun (env_name, old_val) ->
        let () = Unix.putenv env_name old_val in
        return ()
      )
    }

let with_env_appended =
  premap
    (fun (name, what_to_append) ->
       let old = try Unix.getenv name with Not_found -> "" in
       let new_var =
         sprintf "%s%s%s"
           what_to_append
           (if old = "" then "" else ":")
           old
       in
         (name, new_var)
    )
    with_env

end

open WithCombs



(* предполагаем, что находимся в корневой дире проекта *)
let makefile : install_type = object
  method install ~source_dir =
    let open WithM in
    let open Res in
    WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
    let our_project_path = Sys.getcwd () in
    WithRes.bindres with_env_appended
      ("OCAMLPATH", our_project_path </> lib_dir) & fun _old_env1 ->
    WithRes.bindres with_env_appended
      ("PATH", our_project_path </> bin_dir) & fun _old_env2 ->
    let command fmt = Printf.ksprintf Sys.command_ok fmt in
    (let co = "configure" in
     if Sys.file_exists co
     then command "./%s" co
     else return ()
    ) >>= fun () ->
    command "make" >>= fun () ->
    command "make install"
end
