open Config
open Printf
open Types

let show_version = ref false
let opts = Arg.align [
  ("--version",
   Arg.Set show_version,
   "output version information and exit")
]

let () = begin
  Arg.parse opts ignore "brb";
  if !show_version then
    printf "%i\n" Barbra.version;

  let config = parse_config "config" in
  List.iter (fun (name, kind) -> match kind with
    | VCS (url,typ) -> printf "%s: VCS.%s %s\n" name (string_of_vcs_type typ) url
    | FsSrc src -> printf "%s: FsSrc %s\n" name src
    | Local -> printf "%s: Local\n" name
    | HttpArchive (s,_t) -> printf "%s: HttpArchive %s\n" name s
    | FsArchive (s,_t) -> printf "%s: FsArchive %s\n" name s
  ) config
end
