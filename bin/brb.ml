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
  let usage () =
    printf "usage: see TZ1\n"
  in
  begin match List.tl (Array.to_list Sys.argv) with
    | [] | ("--help" | "help") :: _ ->
        usage ()
    | ("--version" | "version") :: _ ->
        printf "%i\n" Barbra.version

    | ("build" :: _) ->
        build ()
    | "run" :: cmd ->
        run cmd

    | cmd :: _ ->
        eprintf "unknown command %S\n" cmd
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
