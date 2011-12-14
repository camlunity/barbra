open Printf

let show_version = ref false
let opts = Arg.align [
  ("--version",
   Arg.Set show_version,
   "output version information and exit")
]

let () =
  Arg.parse opts ignore "brb";
  if !show_version then
    printf "%i\n" Barbra.version
  else begin
    Barbra.cleanup ();
    Barbra.install ()
  end
