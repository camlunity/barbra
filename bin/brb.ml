open Printf

let () =
  let build () =
    begin
      Barbra.cleanup ();
      Barbra.install ()
    end
  in
  let run cmd =
    Res.exn_res (Install.run_with_env cmd)
  in
  begin match List.tl (Array.to_list Sys.argv) with
    | [] | ("build" :: _) ->
        build ()
    | ("--version" | "version") :: _ ->
        printf "%i\n" Barbra.version
    | ("--help" | "help") :: _ ->
        printf "usage: see TZ1\n"
    | "run" :: cmd ->
        run cmd
  end


(* todo: take these strings up, make good "usage" and "help"

let show_version = ref false
let run_list_rev = ref []
let opts = Arg.align [
  ("--version",
   Arg.Set show_version,
   "output version information and exit")
]

let () =
  Arg.parse opts ignore "brb";
  if !show_version then
*)
