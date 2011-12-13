open Types
open Common

include Global


(** [with_config f] Executes a given function, passing parsed config
    file as an argument. *)
let with_config f =
  let conf = base_dir </> brb_conf in
  if Sys.file_exists conf then
    f (Config.parse_config conf)
  else
    failwith "can't find brb.conf in %S" base_dir


(* предполагаем, что текущая директория -- корень проекта *)
let install () =
  let rec go = function
    | [] -> printf "Done"
    | (hname, htyp) :: tconf ->
      let go_temp_dir project_path =
        go &
          (hname, Bundled (Temporary, `Directory, project_path))
          :: tconf
      in begin match htyp with
        | Remote (remote_type, url) ->
          let source = new Source.remote url in
          let project_path = Res.exn_res & source#fetch ~dest_dir:tmp_dir
          in go &
            (hname, Bundled
              (Temporary, (remote_type :> local_type), project_path))
            :: tconf
        | Local ((#remote_type as archive_type), local_path) ->
          let source = new Source.archive archive_type local_path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> hname)
          in go_temp_dir project_path
        | Local (`Directory, local_path) ->
          let () = failwith "todo: copy local dir %S" local_path in
          let project_path = raise Exit in
          go_temp_dir project_path
        | VCS (vcs_type, url) ->
          let source = new Source.vcs vcs_type url in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> hname)
          in go_temp_dir project_path
        | Bundled (Persistent, `Directory, project_path) ->
          let () = failwith "todo: copy persistent dir %S to work dir"
            project_path
          in
          let project_path = raise Exit in
          go_temp_dir project_path
        | Bundled (_, (#remote_type as archive_type), file_path) ->
          let source = new Source.archive archive_type file_path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> hname)
          in go_temp_dir project_path
        | Bundled (Temporary, `Directory, project_path) ->
          let () = Res.exn_res &
            Install.makefile#install ~source_dir:project_path in
          go & (hname, Installed) :: tconf
        | Installed ->
          go tconf
      end
  in begin
    with_config go
  end
