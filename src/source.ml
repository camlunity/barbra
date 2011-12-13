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
    let () = Global.create_dirs () in
    let file_path = dest_dir </> Filename.basename url in
    let open Res in
        command "wget -c --no-check-certificate %s -O %s"
          url file_path >>= fun () -> return file_path
end


class archive archive_type file_path : source_type = object
  method is_available () = List.for_all ensure ["tar"]

  method fetch ~dest_dir =
    let () = Global.create_dirs () in
    let archive_cmd = match archive_type with
      | `Tar -> "tar -xf "
      | `TarGz -> "tar -zxf"
      | `TarBzip2 -> "tar -jxf"
    in

    let open Res in
        command "mkdir -p %s" dest_dir >>= fun () ->
        command "%s %s -C %s" archive_cmd file_path dest_dir >>= fun () ->
        command "rm -rf %s" file_path >>= fun () ->

        (* If [dest_dir] contains a single directory, assume it *is* the
           source dir, otherwise return [dest_dir]. *)
        let files = Array.map ((</>) dest_dir) (Sys.readdir dest_dir)
        in match Array.to_list files with
          | [d] when Sys.is_directory d -> return d
          | _ -> return dest_dir
end


class vcs vcs_type url : source_type = object
  method is_available () = ensure & match vcs_type with
    | Git   -> "git"
    | Hg    -> "hg"
    | Bzr   -> "bzr"
    | Darcs -> "darcs"
    | SVN   -> "svn"
    | CVS   -> "cvs"

  method fetch ~dest_dir =
    let () = Global.create_dirs () in
    let vcs_cmd = match vcs_type with
      | Git   -> "git clone --depth=1"
      | Hg    -> "hg clone"
      | Bzr   -> "bzr branch"
      | Darcs -> "darcs get --lazy"
      | SVN   -> "svn co"
      | CVS   -> failwith "fixme: add clone command for cvs"
    in

    let open Res in
        command "%s %s %s" vcs_cmd url dest_dir >>= fun () ->
        return dest_dir
end


class directory path : source_type = object

  method is_available () = Filew.is_directory path

  method fetch ~dest_dir =
    let () = Global.create_dirs () in
    let () = assert (Filew.is_directory path) in
    if Sys.file_exists dest_dir
    then failwith "directory#fetch: dest_dir=%S must be empty" dest_dir
    else
      let open Res in
      command "cp -R %s %s" path dest_dir >>= fun () ->
      return dest_dir
end


