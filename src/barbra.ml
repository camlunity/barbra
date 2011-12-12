open Types
open Common
open Res

include Global

(* предполагаем, что текущая директория -- корень проекта *)
let install_from conf =
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
              let source = new Source.remote url in
              let project_path = exn_res & source#fetch ~dest_dir:(tmp_dir)
              in go &
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
            | Bundled (_, (#remote_type as archive_type), file_path) ->
              let source = new Source.archive archive_type file_path in
              let project_path = exn_res &
                source#fetch ~dest_dir:(src_dir </> hname)
              in go_temp_dir project_path
            | Bundled (Temporary, `Directory, project_path) ->
                let () = Res.exn_res &
                  Install.makefile#install ~source_dir:project_path in
                go & (hname, Installed) :: tconf
            | Installed ->
                go tconf
          end
    end
  in begin
    makedirs src_dir;
    makedirs tmp_dir;
    go config
  end


let install () =
  let conf = Filename.concat Filename.current_dir_name brb_conf in
  if Sys.file_exists conf then
    install_from conf
  else
    failwith "can't find brb.conf in %S" Filename.current_dir_name
