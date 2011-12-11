open Common

type archive_type = TarGz | TarBzip2

type vcs_type = Git | Svn | Mercurial | Bazaar

type whereis =
  | VCS of string*vcs_type
  | FsSrc of string
  | Local
  | HttpArchive of string*archive_type
  | FsArchive of string*archive_type

type db = (string * whereis) list

let string_of_artype = function
  | TarGz -> "tar.gz" | TarBzip2 -> "tar.bzip2"

let string_of_vcs_type = function
  | Git -> "git" | Svn -> "svn" | Mercurial -> "hg" | Bazaar -> "bzr"

let vcs_type_of_string s = match String.lowercase s with
  | "git" -> Git | "svn" -> Svn | "hg" -> Mercurial | "bzr" -> Bazaar
  | _ -> failwith "unknown VCS type %S" s
