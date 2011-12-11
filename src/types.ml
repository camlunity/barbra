open Printf
open Common

type archive_type = TarGz | TarBzip2 | Tar

type vcs_type = Git | Svn | Hg | Bzr

type whereis =
  | VCS of string*vcs_type
  | FsSrc of string
  | Local
  | HttpArchive of string*archive_type
  | FsArchive of string*archive_type

type db = (string * whereis) list

let string_of_arctype = function
  | TarGz -> "tar.gz" | TarBzip2 -> "tar.bzip2" | Tar -> "tar"

let string_of_vcs_type = function
  | Git -> "git" | Svn -> "svn" | Hg -> "hg" | Bzr -> "bzr"

let vcs_type_of_string s = match String.lowercase s with
  | "git" -> Git | "svn" -> Svn | "hg" -> Hg | "bzr" -> Bzr
  | _ -> failwith "unknown VCS type %S" s

let string_of_dbel (name, wher) = match wher with
  | VCS (url, typ) -> sprintf "%s: VCS.%s %s" name (string_of_vcs_type typ) url
  | FsSrc src -> sprintf "%s: FsSrc %s" name src
  | Local -> sprintf "%s: Local" name
  | HttpArchive (s, _t) -> sprintf "%s: HttpArchive %s" name s
  | FsArchive (s, _t) -> sprintf "%s: FsArchive %s" name s

type ('a, 'e) res = ('a, 'e) Res.res


class type source_type = object
  method is_available : unit -> bool
  (** Returns [true] if this source type handler is available for
      use, i. e. all the required binaries are installed and [false]
      otherwise. *)

  method fetch : dest_dir:string -> (unit, exn) res
  (** Fetches package source to [dest_dir], which is located in
      [Barbra.base_dir]. *)
end

class type install_type = object
  method install : source_dir:string -> (unit, exn) res
  (** Installs packages, located in [source_dir]. *)
end
