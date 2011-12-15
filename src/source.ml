open Types
open Printf
open Common

(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
let ensure cmd =
  Sys.command (sprintf "sh -c 'which %s &> /dev/null'" cmd) = 0


let remote_fn = lazy (
  let open Res in begin
    match (ensure "wget", ensure "curl") with
      | (true, _) -> return & fun ~url ~file_path ->
        exec ["wget"; "-c"; "--no-check-certificate"; url; "-O"; file_path]
      | (_, true) -> return & fun ~url ~file_path ->
        exec ["curl"; "-sS"; "-f"; "-o"; file_path; url]
      | _ -> fail Not_found
  end
)


class remote url : source_type = object
  method is_available () = match Lazy.force remote_fn with
    | `Ok _ -> true
    | `Error _ -> false

  method fetch ~dest_dir =
    let file_path = dest_dir </> Filename.basename url in
    let open Res in begin
      Global.create_dirs ();
      Log.info "Fetching %s to %s" url dest_dir;

      match Lazy.force remote_fn with
        | `Ok f -> f ~url ~file_path >>= fun () -> return file_path
        | `Error _ ->
          (* TODO(bobry): emit an error message, once we add
             #is_available checking to 'Barbra.install'. *)
          failwith "remote#is_available returned false, why calling #fetch?"
    end
end


class archive archive_type file_path : source_type = object
  method is_available () = List.for_all ensure ["tar"]

  method fetch ~dest_dir =
    let archive_cmd = match archive_type with
      | `Tar -> ["tar"; "-xf"]
      | `TarGz -> ["tar"; "-zxf"]
      | `TarBzip2 -> ["tar"; "-jxf"]
    in

    let open Res in begin
      Global.create_dirs ();
      Log.info "Extracting %s to %S" file_path dest_dir;

      mkdir_p dest_dir >>= fun () ->
        exec (archive_cmd @ [file_path; "-C"; dest_dir]) >>= fun () ->
        (Res.wrap1 Sys.remove file_path) >>= fun () ->

        (* If [dest_dir] contains a single directory, assume it *is* the
           source dir, otherwise return [dest_dir]. *)
        let files = Array.map ((</>) dest_dir) (Sys.readdir dest_dir)
        in match Array.to_list files with
          | [d] when Sys.is_directory d -> return d
          | _ -> return dest_dir
    end
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
    let vcs_cmd = match vcs_type with
      | Git   -> ["git"; "clone"; "--depth=1"]
      | Hg    -> ["hg"; "clone"]
      | Bzr   -> ["bzr"; "branch"]
      | Darcs -> ["darcs"; "get"; "--lazy"]
      | SVN   -> ["svn"; "co"]
      | CVS   -> ["cvs"; "co"]
    in

    let open Res in begin
      Global.create_dirs ();
      Log.info
        "Fetching %s repository at %S" (string_of_vcs_type vcs_type) url;

      exec (vcs_cmd @ [url; dest_dir]) >>= fun () ->
      return dest_dir
    end
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
      exec ["cp"; "-R"; path; dest_dir] >>= fun () ->
      return dest_dir
end
