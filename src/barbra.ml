open Types
open Common
open Printf
open Source

let version = 1
and base_dir = Common.base_dir
and brb_conf = "brb.conf"  (* просто имя файла без путей *)


(* предполагаем, что текущая директория -- корень проекта *)
let install_from conf =
  let _src_dir = Filename.concat base_dir "src" in
  let config = Config.parse_config conf in

  let rec go config =
    begin match config with
      | [] -> printf "Done"
      | (hname, htyp) :: tconf ->
          let go_temp_dir project_path =
            go &
              (hname, Bundled (Temporary, `Directory, project_path))
              :: tconf
          in
          begin match htyp with
            | Remote (remote_type, url) ->
                let () = failwith "todo: fetch %S" url in
                let project_path = raise Exit in
                go &
                  (hname, Bundled
                     (Temporary, (remote_type :> local_type), project_path))
                  :: tconf
            | Local (`Directory, local_path) ->
                let () = failwith "todo: copy local dir %S" local_path in
                let project_path = raise Exit in
                go_temp_dir project_path
            | Local ((`Tar | `TarGz | `TarBzip2), local_path) ->
                let () = failwith "todo: extract local archive %S" local_path
                in
                let project_path = raise Exit in
                go_temp_dir project_path
            | VCS (_vcs_type, url) ->
                let () = failwith "todo: clone vcs %S" url in
                let project_path = raise Exit in
                go_temp_dir project_path
            | Bundled (Persistent, `Directory, project_path) ->
                let () = failwith "todo: copy persistent dir %S to work dir"
                  project_path
                in
                let project_path = raise Exit in
                go_temp_dir project_path
            | Bundled (_, (`TarGz | `TarBzip2 | `Tar), file_path) ->
                let () = failwith "todo: unpack local archive %S" file_path in
                let project_path = raise Exit in
                go_temp_dir project_path
            | Bundled (Temporary, `Directory, project_path) ->
                let () = failwith "todo: install from %S" project_path in
                go & (hname, Installed) :: tconf
            | Installed ->
                go tconf
          end
    end
(*
    (fun (pkg, typ) ->
      printf "I: Installing %S ..\n" pkg;

      let source = match typ with
        | Remote (archive_type, uri) ->
          new remote_archive uri archive_type
        | _ -> failwith "unfetchable type for %S" pkg
      and dest_dir = Filename.concat src_dir pkg in

      if source#is_available () then (
        makedirs dest_dir;
        ignore & source#fetch ~dest_dir
      ) else
        failwith "fixme: how to report this?"
*)
  in
    go config


let install () =
  let conf = Filename.concat Filename.current_dir_name brb_conf in
  if Sys.file_exists conf then
    install_from conf
  else
    failwith "can't find brb.conf in %S" Filename.current_dir_name
