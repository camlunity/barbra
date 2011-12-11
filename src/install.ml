open Types


let makefile : install_type = object
  method install ~source_dir =
    let open WithM in
    let open Res in
      WithRes.bindres WithRes.with_sys_chdir source_dir
      (fun _old_path ->
         let command fmt = Printf.ksprintf Sys.command_ok fmt in
         command "./configure" >>= fun () ->
         command "make" >>= fun () ->
         command "make install"
      )
end
