open Types
open Printf


(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
let ensure cmd =
  Sys.command (sprintf "sh -c 'which %s &> /dev/null'" cmd) = 0


class remote_archive uri archive_type : source_type = object
  method is_available () = List.for_all ensure ["wget"; "tar"]

  method fetch ~dest_dir =
    let fn = Filename.basename uri in
    let archive_cmd = match archive_type with
      | Tar -> "tar -xf "
      | TarGz -> "tar -zxf"
      | TarBzip2 -> "tar -jxf"
    in

    let open WithM in
    let open Res in
      WithRes.bindres WithRes.with_sys_chdir dest_dir
      (fun _old_path ->
         let command fmt = Printf.ksprintf Sys.command_ok fmt in
         command "wget --no-check-certificate %s -O %s" uri fn >>= fun () ->
         command "%s %s" archive_cmd fn
      )
end
