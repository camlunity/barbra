open Common

type remote_type = [ `TarGz | `TarBzip2 | `Tar ]
type local_type  = [ remote_type | `Directory ]
type vcs_type = Git | Hg | Bzr | Darcs | SVN | CVS

type package =
  | Recipe of string
  | Remote of remote_type * string
  | Local of local_type * string
  | VCS of vcs_type * string
  | Bundled of local_type * string
  | Temporary of local_type * string
  | Installed

type dep =
    {
      name        : string;
      package     : package;
      requires    : string list;
      flags       : string list;
      patches     : string list;
      build_cmd   : string;
      install_cmd : string
    }

let vcs_type_of_string s = match String.lowercase s with
  | "git"   -> Git
  | "hg"    -> Hg
  | "bzr"   -> Bzr
  | "darcs" -> Darcs
  | "cvs"   -> CVS
  | "svn"   -> SVN
  | _ -> failwithf "unknown VCS type %S" s

and string_of_vcs_type = function
  | Git     -> "git"
  | Hg      -> "mercurial"
  | Bzr     -> "bazaar"
  | Darcs   -> "darcs"
  | CVS     -> "cvs"
  | SVN     -> "subversion"


type ('a, 'e) res = ('a, 'e) Res.res


class type source_type = object
  val is_available : bool
  (** Returns [true] if this source type handler is available for
      use, i. e. all the required binaries are installed and [false]
      otherwise. *)

  method fetch : dest_dir:string -> (string, exn) res
  (** Fetches package source to [dest_dir], which is located in
      [Barbra.base_dir]. *)
end

class type install_type = object
  method install : source_dir:string ->
                   build_cmd:string ->
                   install_cmd:string ->
                   flags:string list ->
                   patches:string list -> (unit, exn) res
  (** Installs packages, located in [source_dir]. *)
end


type cap =
  [ `Executable of (string * string)  (* (executable_name, probe_option) *)
  ]
