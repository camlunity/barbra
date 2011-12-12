open Printf
open Common

type archive_type = TarGz | TarBzip2 | Tar
type vcs_type = Git | Hg | Bzr | Darcs | SVN | CVS

type package_type =
  | VCS of string * vcs_type
  | Archive of string * archive_type

type package = [ `Local of package_type
               | `Remote of package_type
               | `Bundled of string
               ]

type db = (string * package) list


let string_of_arctype = function
  | TarGz    -> "tar.gz"
  | TarBzip2 -> "tar.bzip2"
  | Tar      -> "tar"

let string_of_vcs_type = function
  | Git   -> "git"
  | Hg    -> "hg"
  | Bzr   -> "bzr"
  | Darcs -> "darcs"
  | SVN   -> "svn"
  | CVS   -> "cvs"

let vcs_type_of_string s = match String.lowercase s with
  | "git"   -> Git
  | "hg"    -> Hg
  | "bzr"   -> Bzr
  | "darcs" -> Darcs
  | "cvs"   -> CVS
  | "svn"   -> SVN
  | _ -> failwith "unknown VCS type %S" s


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
