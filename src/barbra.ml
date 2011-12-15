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
    Log.error "can't find brb.conf in %S" base_dir


let cleanup () =
  if Filew.is_directory dep_dir then
    exec_exn ["rm"; "-rf"; dep_dir]


(* assuming we are in project's root dir *)
let install () =
  let rec go = function
    | [] -> Log.info "Done!"
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
        | VCS (vcs_type, url) ->
          let source = new Source.vcs vcs_type url in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> hname)
          in go_temp_dir project_path
        | Local (`Directory, path)
        | Bundled (Persistent, `Directory, path) ->
          let source = new Source.directory path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> hname) in
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
  in with_config go
