open Config
open Printf

let config = Config.parse_config "config" 

let () = List.iter (fun (name,wher) -> match wher with
  | VCS (url,typ) -> printf "%s: VCS.%s %s\n" name (string_of_vcs_type typ) url
  | FsSrc src -> printf "%s: FsSrc %s\n" name src
  | Local -> printf "%s: Local\n" name
  | HttpArchive (s,t) -> printf "%s: HttpArchive %s\n" name s 
  | FsArchive (s,t) -> printf "%s: FsArchive %s\n" name s
) config
