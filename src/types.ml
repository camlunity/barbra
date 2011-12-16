open Printf
open Common

type remote_type = [ `TarGz | `TarBzip2 | `Tar ]
type local_type  = [ remote_type | `Directory ]
type vcs_type = Git | Hg | Bzr | Darcs | SVN | CVS
type bundle_type = Temporary | Persistent

type package =
  | Remote of remote_type * string
  | Local of local_type * string
  | VCS of vcs_type * string
  | Bundled of bundle_type * local_type * string
  | Installed

type db = (string * package) list


let vcs_type_of_string s = match String.lowercase s with
  | "git"   -> Git
  | "hg"    -> Hg
  | "bzr"   -> Bzr
  | "darcs" -> Darcs
  | "cvs"   -> CVS
  | "svn"   -> SVN
  | _ -> failwith "unknown VCS type %S" s

and string_of_vcs_type = function
  | Git     -> "git"
  | Hg      -> "mercurial"
  | Bzr     -> "bazaar"
  | Darcs   -> "darcs"
  | CVS     -> "cvs"
  | SVN     -> "subversion"


type ('a, 'e) res = ('a, 'e) Res.res


class type source_type = object
  method is_available : unit -> bool
  (** Returns [true] if this source type handler is available for
      use, i. e. all the required binaries are installed and [false]
      otherwise. *)

  method fetch : dest_dir:string -> (string, exn) res
  (** Fetches package source to [dest_dir], which is located in
      [Barbra.base_dir]. *)
end

class type install_type = object
  method install : source_dir:string -> (unit, exn) res
  (** Installs packages, located in [source_dir]. *)
end


type cap =
  [ `Executable of string
  ]
