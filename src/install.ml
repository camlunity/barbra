open Common
open Types
open Global


let getenv_or_empty env_name =
  try Unix.getenv env_name with Not_found -> ""

let prepend_path what_to_prepend old_path =
   sprintf "%s%s%s"
     what_to_prepend
     (if old_path = "" then "" else ":")
     old_path

let line_of_process cmdline =
  Filew.with_process_in cmdline & fun inch ->
  Filew.input_line_opt inch

module WithCombs = struct
  open WithM
  open Res
  open WithRes

(* variable that was not set will be restored to "". *)
let with_env =
    { cons = (fun (env_name, new_val) ->
        let old_val = getenv_or_empty env_name in
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
       let old = getenv_or_empty name in
       let new_var = prepend_path what_to_prepend old in
       (name, new_var)
    )
    with_env

end

open WithCombs


(* предполагаем, что находимся в корневой дире проекта
   todo: может давайте везде подобное предполагать?
         А то и вынести абсолютные пути вместо относительных
         куда-нибудь Global?
 *)
let generate_findlib_configs () : unit =
  let our_project_path = Sys.getcwd () in
  let etc_dir = our_project_path </> etc_dir in
  let dest_dir = our_project_path </> lib_dir </> "site-lib" in
  let new_ld_conf = our_project_path </> lib_dir </> "ld.conf" in
  let () = assert (Sys.is_directory etc_dir) in
  let path =
    let old_path = getenv_or_empty "OCAMLPATH" in
    let old_path =
      if old_path <> ""
      then
        old_path
      else
        try
          match line_of_process "ocamlfind printconf path" with
          | None -> ""
          | Some line -> line
        with
          Unix.Unix_error _ -> ""
    in
      prepend_path dest_dir old_path
  in
  let () =
    Filew.with_file_out_bin (etc_dir </> "findlib.conf") & fun outch ->
    List.iter
      (fun (k, v) -> fprintf outch "%s = %S\n%!" k v)
      [ ("path", path)
      ; ("destdir", dest_dir)
      ]
  in
  let () =
    begin match line_of_process "ocamlfind printconf ldconf" with
    | None -> ()
    | Some old_ld_conf ->
        Filew.copy_file old_ld_conf new_ld_conf
    end
  in
    ()


(* предполагаем, что находимся в корневой дире проекта *)
let makefile : install_type = object
  method install ~source_dir =
    let open WithM in
    let open Res in
    WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
    let our_project_path = Sys.getcwd () in
    WithRes.bindres with_env_prepended
      ("OCAMLPATH", our_project_path </> lib_dir) & fun _old_env1 ->
    WithRes.bindres with_env_prepended
      ("PATH", our_project_path </> bin_dir) & fun _old_env2 ->
    WithRes.bindres with_env
      ( "OCAMLFIND_CONF"
      , our_project_path </> etc_dir </> "findlib.conf"
      ) & fun _old_env3 ->
    WithRes.bindres with_env
      ( "OCAMLFIND_LDCONF"
      , our_project_path </> lib_dir </> "ld.conf"
      ) & fun _old_env4 ->
    let command fmt = Printf.ksprintf Sys.command_ok fmt in
    (let co = "configure" in
     if Sys.file_exists co
     then command "./%s" co
     else return ()
    ) >>= fun () ->
    command "make" >>= fun () ->
    command "make install"
end
