open Common
open Types
open Printf
open WithM
open Global

module List = ListLabels
module G = Global

let (>>=) = Res.(>>=)

let makefile : install_type = object
  method install ~source_dir ~build_cmd ~install_cmd ~flags ~patches = begin
    G.create_dirs ();
    Env.write_env ();

    Log.info "Applying patches";
    WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
      List.iter patches ~f:(fun patch ->
        let abs_patch = if Filename.is_relative patch then
            G.base_dir </> patch
          else
            patch
        in
        exec_exn ["patch"; "-p1"; "-i"; expand_vars abs_patch];
        Log.debug "Applied patch %S" patch;
      );

      let make_wrapper cmd =
	match String.nsplit (expand_vars cmd) " " with
          | cmd -> exec cmd
      in
    WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
      Env.with_env & fun () ->
        (if Sys.file_exists "configure" then
            let flags = List.map ~f:expand_vars flags in
            let flags =
              if Sys.file_exists "_oasis"
              (* maybe we should always pass --prefix,
                 not only for oasis projects *)
              then
                ["--prefix"; G.dep_dir] @ flags
              else
                flags
            in
            if (Unix.stat "configure").Unix.st_perm land 0o100 <> 0 then
              exec (["./configure"] @ flags)
            else
              exec (["sh" ; "./configure"] @ flags)
         else
            Res.return ()
        ) >>= (fun () -> make_wrapper build_cmd
        ) >>= fun () -> make_wrapper install_cmd
  end
end
