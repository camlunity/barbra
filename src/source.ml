open Types
open Printf
open Common

(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
let ensure cmd =
  Sys.command (sprintf "sh -c 'which %s &> /dev/null'" cmd) = 0


class remote url : source_type = object
  method is_available () = List.for_all ensure ["wget"]

  method fetch ~dest_dir =
    let file_path = dest_dir </> Filename.basename url in
    let open Res in
        let command fmt = Printf.ksprintf Sys.command_ok fmt in
        let res = if Sys.file_exists file_path then
            return ()
          else
            command "wget --no-check-certificate %s -O %s" url file_path
        in res >>= fun () -> return file_path
end


class archive archive_type file_path : source_type = object
  method is_available () = List.for_all ensure ["tar"]

  method fetch ~dest_dir =
    let archive_cmd = match archive_type with
      | `Tar -> "tar -xf "
      | `TarGz -> "tar -zxf"
      | `TarBzip2 -> "tar -jxf"
    in

    let open Res in
        let command fmt = Printf.ksprintf Sys.command_ok fmt in
        command "mkdir -p %s" dest_dir >>= fun () ->
        command "%s %s -C %s" archive_cmd file_path dest_dir >>= fun () ->

        (* If [dest_dir] contains a single directory, assume it *is* the
           source dir, otherwise return [dest_dir]. *)
        let files = Array.map ((</>) dest_dir) (Sys.readdir dest_dir)
        in match List.filter Sys.is_directory (Array.to_list files) with
          | [d] -> return d
          | _   -> return dest_dir
end
