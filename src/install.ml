open Common
open Types


(* variable that was not set will be restored to "". *)
let with_env =
  let open WithM in
  let open Res in
  let open WithRes in
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


(* предполагаем, что находимся в корневой дире проекта *)
let makefile : install_type = object
  method install ~source_dir =
    let open WithM in
    let open Res in
      WithRes.bindres WithRes.with_sys_chdir source_dir
      (fun _old_path ->
         let n = "OCAMLPATH" in
         let our_project_path = Sys.getcwd () in
         let new_ocamlpath =
           let old = try Unix.getenv n with Not_found -> "" in
           sprintf "%s%s%s"
             (our_project_path
              /* Filename.concat */ base_dir
              /* Filename.concat */ "lib"
             )
             (if old = "" then "" else ":")
             old
         in
         WithRes.bindres with_env (n, new_ocamlpath)
         (fun _old_env ->
            let command fmt = Printf.ksprintf Sys.command_ok fmt in
            command "./configure" >>= fun () ->
            command "make" >>= fun () ->
            command "make install"
         )
      )
end
