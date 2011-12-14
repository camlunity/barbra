open Types
open Printf
open Common

(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
let ensure cmd =
  Sys.command (sprintf "sh -c 'which %s &> /dev/null'" cmd) = 0


let remote_alternative
 : ((url:string -> file_path:string -> (string, exn) Res.res, exn) Res.res)
   Lazy.t
 = 
  lazy
    (let open Res in
     let ensure = wrap1 ensure in
     ensure "wget" >>= function
     | true -> return & fun ~url ~file_path ->
         exec ["wget"; "-c"; "--no-check-certificate"; url; "-O"; file_path]
         >>= fun () -> return file_path
     | false ->
     ensure "curl" >>= function
     | true -> return & fun ~url ~file_path ->
         exec ["curl"; "-sS"; "-f"; "-o"; file_path; url]
         >>= fun () -> return file_path
     | false ->
         fail Not_found
    )


class remote url : source_type = object

  method is_available () =
    let open Res in
    exn_res & catch
      (fun () -> Lazy.force remote_alternative >>= fun _ -> return true)
      (function Not_found -> return false | e -> fail e)

  method fetch ~dest_dir =
    let () = Global.create_dirs () in
    let file_path = dest_dir </> Filename.basename url in
    let open Res in
    begin match Lazy.force remote_alternative with
      | `Error Not_found ->
          failwith "remote#is_available returned false, why calling #fetch?"
      | `Error e -> fail e
      | `Ok f -> f ~url ~file_path
    end
end


class archive archive_type file_path : source_type = object
  method is_available () = List.for_all ensure ["tar"]

  method fetch ~dest_dir =
    let () = Global.create_dirs () in
    let archive_cmd = match archive_type with
      | `Tar -> ["tar"; "-xf"]
      | `TarGz -> ["tar"; "-zxf"]
      | `TarBzip2 -> ["tar"; "-jxf"]
    in

    let open Res in
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
      | Git   -> ["git"; "clone"; "--depth=1"]
      | Hg    -> ["hg"; "clone"]
      | Bzr   -> ["bzr"; "branch"]
      | Darcs -> ["darcs"; "get"; "--lazy"]
      | SVN   -> ["svn"; "co"]
      | CVS   -> ["cvs"; "co"]
    in

    let open Res in
        exec (vcs_cmd @ [url; dest_dir]) >>= fun () ->
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
      exec ["cp"; "-R"; path; dest_dir] >>= fun () ->
      return dest_dir
end


