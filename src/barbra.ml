open Types
open Common

include Global


(** [with_config f] Executes a given function, passing parsed config
    file as an argument. *)
let with_config f =
  let conf = base_dir </> brb_conf in
  if Sys.file_exists conf then
    f (Config.from_file conf)
  else
    Log.error "can't find brb.conf in %S" base_dir


let cleanup () =
  if Filew.is_directory dep_dir then
    Fs_util.remove_directory_recursive dep_dir


(* assuming we are in project's root dir *)
let build_deps () =
  let rec go = function
    | [] -> Log.info "Dependencies built successfully!"
    | ({ name; package; flags; targets; patches; _ } as dep) :: conf ->
      let go_temp_dir project_path =
        go & { dep with package = Temporary (`Directory, project_path) }
          :: conf
      in begin match package with
        | Remote (remote_type, url) ->
          let source = new Source.remote url in
          let project_path = Res.exn_res & source#fetch ~dest_dir:tmp_dir
          in go & { dep with package =
              Temporary ((remote_type :> local_type), project_path) }
            :: conf
        | Local ((#remote_type as archive_type), local_path) ->
          let source = new Source.archive archive_type local_path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> name)
          in go_temp_dir project_path
        | VCS (vcs_type, url) ->
          let source = new Source.vcs vcs_type url in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> name)
          in go_temp_dir project_path
        | Local (`Directory, path)
        | Bundled (`Directory, path) ->
          let source = new Source.directory path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> name) in
          go_temp_dir project_path
        | Bundled ((#remote_type as archive_type), file_path) ->
          let source = new Source.archive archive_type file_path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> name)
          in begin
            Log.debug "Keeping successfully unpacked bundled %S" file_path;
            go_temp_dir project_path
          end
        | Temporary ((#remote_type as archive_type), file_path) ->
          let source = new Source.archive archive_type file_path in
          let project_path = Res.exn_res &
            source#fetch ~dest_dir:(tmp_dir </> name)
          in begin
            Log.info "Removing successfully unpacked %S" file_path;
            Sys.remove file_path;
            go_temp_dir project_path
          end
        | Temporary (`Directory, project_path) ->
          let () = Res.exn_res &
            Install.makefile#install
            ~source_dir:project_path
            ~flags
            ~targets
            ~patches
            ~installcmd: dep.installcmd
          in

          Log.info "Removing successfully built %S" project_path;
          (* Note(gds): Kakadu recommends to allow user to decide:
             remove bundled temporary files or not. *)
          let () = Fs_util.remove_directory_recursive project_path in
          go & { dep with package = Installed } :: conf
        | Installed | Recipe _ ->
          go conf
      end
  in with_config go


let build_project () = begin
  Log.info "Building the project (from %S)" base_dir;
  Res.exn_res & Install.makefile#install
    ~source_dir:base_dir
    ~flags:[]
    ~targets:[]
    ~installcmd:"make install"
    ~patches:[];
  Log.info "Project built succesfully!"
end

let deps_are_built () = Filew.is_directory dep_dir


let build_gen ~proj () =
  let () =
    if deps_are_built ()
    then ()
    else build_deps ()
  in
  if proj then build_project () else ()


let rebuild_gen ~proj () = begin
  cleanup ();
  build_gen ~proj ();
end


let build () = build_gen ~proj:true ()

let rebuild () = rebuild_gen ~proj:true ()

let build_deps () = build_gen ~proj:false ()

let rebuild_deps () = rebuild_gen ~proj:false ()


let run_with_env cmd =
  Res.exn_res (Env.exec_with_env cmd)
