open Common
open Types
open Printf
open WithM

module List = ListLabels
module G = Global

let (>>=) = Res.(>>=)

let makefile : install_type = object
  method install ~source_dir ~build_cmd ~install_cmd ~flags ~patches = begin
    G.create_dirs ();
    Env.write_env ();

    Log.info "Applying patches";
    WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
      List.iter patches ~f:(fun p ->
        let abs_p = G.base_dir </> p in
        exec_exn ["patch"; "-p1"; "-i"; abs_p];
        Log.debug "Applied patch %S" p;
      );

    WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
      Env.with_env & fun () ->
        (if Sys.file_exists "configure" then
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
        ) >>= fun () -> exec (String.nsplit build_cmd " ") >>= fun () ->
        (* FIXME(superbobry): use $MAKE as default command and resolve
           env variables with a special function. *)
        match String.nsplit install_cmd " " with
          | "make" :: args ->
            exec (getenv ~default:"make" "MAKE" :: args)
          | cmd -> exec cmd
  end
end
