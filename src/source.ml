open Types
open Printf
open Common

module G = Global

(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
let ensure cmd =
  Sys.command (sprintf "sh -c 'which %s &> /dev/null'" cmd) = 0


class remote_archive archive_type uri : source_type = object
  method is_available () = List.for_all ensure ["wget"; "tar"]

  method fetch ~dest_dir =
    let () = makedirs dest_dir in  (** FIXME(bobry): move it to Barbra? *)
    let archive_fn  = G.tmp_dir </> Filename.basename uri in
    let archive_cmd = match archive_type with
      | `Tar -> "tar -xf "
      | `TarGz -> "tar -zxf"
      | `TarBzip2 -> "tar -jxf"
    in

    let open Res in
        let command fmt = Printf.ksprintf Sys.command_ok fmt in
        command "wget --no-check-certificate %s -O %s" uri archive_fn >>= fun () ->
        command "%s %s -C %s" archive_cmd archive_fn dest_dir >>= fun () ->
        return dest_dir
end
