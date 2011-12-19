open Printf

let usage_txt = "\
brb <command or option>:\n\
\  help | --help         this help\n\
\  version | --version   output version\n\
\  build                 build the project in the current directory,\n\
\                        assuming that \"_dep\" either doesn't exist or\n\
\                        contains built dependencies\n\
\  clean                 remove built dependencies (\"_dep\" directory)\n\
\  rebuild               rebuilds dependencies and the project\n\
\  run cmd arg1 .. argN  run \"cmd arg1 .. argN\" with environment that\n\
\                        allows ocamlfind use libraries installed in\n\
\                        \"_dep\" and allows to run programs installed in\n\
\                        \"_dep/bin\".  The same effect as with shell\n\
\                        command \"( . _dep/env.sh ; cmd arg1 .. argN)\"\n\
\                        when \"_dep/env.sh\" does exist\n\
\  build-deps            build project's dependencies, assuming that\n\
\                        \"_dep\" either doesn't exist or contains built\n\
\                        dependencies\n\
\  rebuild-deps          rebuild project's dependencies\n\
"

let () =
  let noargs cmd args =
    if args <> [] then begin
      eprintf "brb: command %S does not accept arguments" cmd;
      exit 1
    end else ()
  in
  begin match List.tl (Array.to_list Sys.argv) with
    | [] | ("--help" | "help") :: _ ->
        printf "usage: %s%!" usage_txt
    | ("--version" | "version") :: _ ->
        printf "%s\n" Barbra.version

    | "build" as c :: args ->
        begin
          noargs c args;
          Barbra.build ();
        end
    | "run" :: cmd ->
        Barbra.run_with_env cmd
    | "clean" as c :: args ->
        begin
          noargs c args;
          Barbra.cleanup ();
        end
    | "rebuild" as c :: args ->
        begin
          noargs c args;
          Barbra.rebuild ();
        end

    | "build-deps" as c :: args ->
        begin
          noargs c args;
          Barbra.build_deps ();
        end

    | "rebuild-deps" as c :: args ->
        begin
          noargs c args;
          Barbra.rebuild_deps ();
        end

    | cmd :: _ ->
        eprintf "unknown command %S\n" cmd
  end
