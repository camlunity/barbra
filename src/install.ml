open Common
open Types
open Printf
open WithM

module List = ListLabels
module G = Global

let (>>=) = Res.(>>=)

let guess_command installcmd =
  try
    let (i,l) = String.index installcmd ' ', String.length installcmd in
    (String.sub installcmd 0 i, String.sub installcmd (i+1) (l-i-1) )
  with
    | Not_found -> (installcmd,"")

let makefile : install_type = object
  method install ~source_dir ~flags ~targets ~patches ~buildcmd ~installcmd = begin
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
        let make = getenv ~default:"make" "MAKE" in
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
        ) >>= fun () -> (
        match buildcmd with
          | "make" ->
            let () = Log.info "Starting Makefile build" in
            exec (make :: targets)
          | _ ->
            exec (buildcmd :: targets)
        ) >>= fun () ->
        let (cmd,args) = guess_command installcmd in
        let cmd = if cmd = "make" then make else cmd in
        exec [cmd; args]
  end
end
