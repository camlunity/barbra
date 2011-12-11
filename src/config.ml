
open Common
open Types


let read_all_lines ch =
  let lines = ref [] in
  try
    while true; do lines := input_line ch :: !lines done;
    []
  with End_of_file ->
    List.rev !lines


let parse lines =
  let ans = ref [] in
  let add item = ans := item :: !ans in
  List.iter (fun s ->
    if String.length s > 0 then
      try
        Scanf.sscanf s "dep %s %s %s" (fun name typ src ->
          match String.lowercase typ with
            | "local"       -> add (name,Local)
            | "http-tar-gz"    -> add (name,HttpArchive (src,TarGz))
            | "fs-tar"       -> add (name,FsArchive   (src,Tar))
            | "svn" | "hg"
            | "git" | "bzr" -> add (name,VCS (src,vcs_type_of_string typ) )
            | "fs-src"      -> add (name,FsSrc src)
            | _             -> print_endline "unsupported delivery method"
        )
      with
          End_of_file -> ()
  ) lines;
  List.rev !ans


let parse_config filename =
  let lines = with_file_in filename read_all_lines in
  parse lines


let parse_string st =
  let lines = String.nsplit st "\n" in
  parse lines
