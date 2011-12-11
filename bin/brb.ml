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
  List.iter print_endline (List.map string_of_dbel config)
end
