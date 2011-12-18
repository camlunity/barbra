open Types
open Printf
open Common


(** [ensure cmd] Same as [ensure], but exits if a given command
    [cmd] is missing. *)
let ensure_exn cmd opt =
  Syscaps.ensure cmd opt || Log.error "Missing executable: %S" cmd

let remotes =
  [ ( `Executable ("wget", "--version")
    , fun ~url ~file_path ->
        exec ["wget"; "-c"; "--no-check-certificate"; url; "-O"; file_path]
    )
  ; ( `Executable ("curl", "--version")
    , fun ~url ~file_path ->
        exec ["curl"; "-sS"; "-f"; "-o"; file_path; url]
    )
  ; ( `Executable ("GET", "-v")
       (* note: it's acceptable only for http://, maybe we should check it. *)
    , fun ~url ~file_path ->
        exec ["sh"; "-c";
          sprintf "GET -t 30 %s > %s"
            (Filename.quote url)
            (Filename.quote file_path)
        ]
    )
  ]

let remote_fn = lazy (Syscaps.first remotes)


class remote url : source_type = object
  val is_available = match Lazy.force remote_fn with
    | `Ok _ -> true
    | `Error () ->
        Log.error "Missing executable for 'remote' backend!"

  method fetch ~dest_dir =
    let file_path = dest_dir </> Filename.basename url in
    let open Res in begin
      Global.create_dirs ();
      Log.info "Fetching %s to %s" url dest_dir;

      match Lazy.force remote_fn with
        | `Ok f -> f ~url ~file_path >>= fun () -> return file_path
        | `Error () -> assert false  (* impossible *)
    end
end


let has_tar = lazy (ensure_exn "tar" "--version")
(* todo: replace with Syscaps when more archive extractors will exist *)

class archive archive_type file_path : source_type = object
  val is_available = Lazy.force has_tar

  method fetch ~dest_dir =
    let archive_cmd = match archive_type with
      | `Tar -> ["tar"; "-xf"]
      | `TarGz -> ["tar"; "-zxf"]
      | `TarBzip2 -> ["tar"; "-jxf"]
    in

    let open Res in begin
      Global.create_dirs ();
      Log.info "Extracting %s to %S" file_path dest_dir;

      exec ["mkdir"; "-p"; dest_dir] >>= fun () ->
      exec (archive_cmd @ [file_path; "-C"; dest_dir]) >>= fun () ->

      (* If [dest_dir] contains a single directory, assume it *is* the
         source dir, otherwise return [dest_dir]. *)
      let files = Array.map ((</>) dest_dir) (Sys.readdir dest_dir)
      in match Array.to_list files with
        | [d] when Sys.is_directory d -> return d
        | _ -> return dest_dir
    end
end


let list_assoc_opt a b = try some & List.assoc a b with Not_found -> None

let has_vcs =
  let f cmd opt = lazy (ensure_exn cmd opt) in
  let v = "--version" in
  let lst =
    [ Git   , f "git" v
    ; Hg    , f "hg" v
    ; Bzr   , f "bzr" "version"
    ; Darcs , f "darcs" v
    ; SVN   , f "svn" v
    ; CVS   , f "cvs" "-v"
    ]
  in
    fun vcs_type ->
      match list_assoc_opt vcs_type lst with
      | None -> Log.error "internal error: Source.has_vcs list is incomplete"
      | Some l -> Lazy.force l


class vcs vcs_type url : source_type = object
  val is_available = has_vcs vcs_type

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
  val is_available = Filew.is_directory path ||
    Log.error "Not a directory: %S" path

  method fetch ~dest_dir =
    let open Res in begin
      Global.create_dirs ();

      (* FIXME(bobry): do we need to check for existance? *)
      exec ["cp"; "-R"; path; dest_dir] >>= fun () ->
      return dest_dir
    end
end
