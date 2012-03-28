open Types
open Common

include Global

(* Internal. *)

let build_deps ?(clear_tmp=true) = 
  let rec go = function
  | [] -> Log.info "Dependencies built successfully!"
  | ({ name; package; _ } as dep) :: conf ->
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
            ~build_cmd:dep.build_cmd
            ~install_cmd:dep.install_cmd
            ~flags:dep.flags
            ~patches:dep.patches
          in

          let () = if clear_tmp then (
            Log.info "Removing successfully built %S" project_path;
	    Fs_util.remove_directory_recursive project_path 
	  ) in
          go & { dep with package = Installed } :: conf
        | Installed | Recipe _ ->
          go conf
      end
  in go

and build_project () = begin
  Log.info "Building the project (from %S)" base_dir;
  Res.exn_res & Install.makefile#install
    ~source_dir:base_dir
    ~build_cmd:"make"
    ~install_cmd:"make install"
    ~flags:[]
    ~patches:[];
  Log.info "Project built successfully!"
end

(* Public API. *)

let cleanup () =
  if Filew.is_directory dep_dir then
    Fs_util.remove_directory_recursive dep_dir

let build ?(clear_tmp=true) ?(look_system_packs=true) ~only_deps ~force_build =
  let open Config in
      let { deps; _ } = resolve ~look_system_packs (from_file (base_dir </> brb_conf)) in
      if not (Filew.is_directory dep_dir) || force_build then begin
        cleanup ();
        build_deps ~clear_tmp deps;
        if not only_deps then
          build_project ()
      end

let update () =
  if Filew.is_directory (recipe_dir ()) then
    let open WithM in
    let open WithRes in
        (* FIXME(superbobry): get rid of 'Res'! *)
        let res = bindres with_sys_chdir (recipe_dir()) & fun _old_path ->
          exec ["git"; "pull"; "origin"; "master"]
        in Res.exn_res res
  else
    exec_exn ["git"; "clone"; "https://github.com/camlunity/purse.git";
              recipe_dir()]

let list () =
  let open Config in
      let { world; _ } = from_file (base_dir </> brb_conf) in
      world#iter ~f:(Printf.printf "%s/%s\n")

let install recipes =
    (* TODO(superbobry): do not reinstall already installed packages. *)
    let open Config in
        let conf = from_file (base_dir </> brb_conf) in
        let deps = List.map
          ~f:(fun recipe -> conf.world#resolve_any ~recipe) recipes
        in

        (* Recursively resolve all dependencies and build the resulting
           list of deps. *)
        let { deps; _ } = resolve { conf with deps } in build_deps deps

and run_with_env cmd =
  Res.exn_res (Env.exec_with_env cmd)
