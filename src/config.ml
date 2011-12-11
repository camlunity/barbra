open Printf

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
  | _ -> assert false

let read_all_lines ch = 
  let lines = ref [] in
  try
    while true; do lines := input_line ch :: !lines done; 
    []
  with End_of_file ->
    List.rev !lines

let parse_config filename = 
  let h = open_in filename in
  let ans = ref [] in
  let add item = ans := item :: !ans in
  let lines = read_all_lines h in
  close_in h;

  List.iter (fun s ->
    if String.length s > 0 then
      try
	Scanf.sscanf s "dep %s %s %s" (fun name typ src ->
	  match String.lowercase typ with
	    | "local"       -> add (name,Local)
	    | "http-tar"    -> add (name,HttpArchive (src,TarGz)) 
	    | "fs-ar"       -> add (name,FsArchive   (src,TarGz)) 
	    | "svn" | "hg"
	    | "git" | "bzr" -> add (name,VCS (src,vcs_type_of_string typ) )
	    | "fs-src"      -> add (name,FsSrc src)
	    | _             -> print_endline "bad line"
	)
      with
	  End_of_file -> ()
  ) lines;
  List.rev !ans
;;
