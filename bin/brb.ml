open Common


let () = SubCommand.register & SubCommand.make
  ~name:"build"
  ~synopsis:"Build the project in the current directory"
  ~help:("Assumes that '_dep' directory doesn't exist or contains\n" ^
         "*already* built dependencies, listed in 'brb.conf'.")
  Barbra.build
and () = SubCommand.register & SubCommand.make
  ~name:"build-deps"
  ~synopsis:"Build project dependencies"
  ~help:("Assumes that '_dep' directory doesn't exist or contains\n" ^
         "*already* built dependencies, listed in 'brb.conf'.")
  Barbra.build_deps
and () = SubCommand.register & SubCommand.make
  ~name:"rebuild"
  ~synopsis:"Rebuild all dependencies along with the project"
  Barbra.rebuild
and () = SubCommand.register & SubCommand.make
  ~name:"rebuild-deps"
  ~synopsis:"Rebuild all project dependencies"
  Barbra.rebuild_deps
and () = SubCommand.register & SubCommand.make
  ~name:"clean"
  ~synopsis:"Remove '_dep' directory with built dependencies"
  Barbra.cleanup
and () =
  let args = ref [] in
  let cmd = SubCommand.make
    ~name:"run"
    ~synopsis:"Run a command in 'barbra' environment"
    ~help:("Uses '_dep/env.sh' to point some of 'ocamlfind' environmental\n" ^
           "variables to the '_dep' directory, which allows 'ocamlfind'  \n" ^
           "to use binaries and libraries, installed by 'brb'.")
    ~usage:"cmd [args*]"
    (fun () -> Barbra.run_with_env !args)
  in

  SubCommand.(register { cmd with anon = fun arg -> args := arg :: !args})
and () =
  let arg = ref "" in
  let cmd = SubCommand.make
    ~name:"help"
    ~synopsis:"Display help for a subcommand"
    ~help:("This subcommand display help of other subcommands or of " ^
           "'all' subcommands.")
    ~usage:"[subcommand|all]"
    (fun () ->
      let hext = match !arg with
        | ""    -> `NoSubCommand
        | "all" -> `AllSubCommands
        | _     -> `SubCommand !arg
      in ArgExt.pp_print_help hext Format.std_formatter ())
  in

  SubCommand.(register { cmd with anon = (:=) arg })


let () =
  try
    ArgExt.parse ()
  with exc ->
    if Printexc.backtrace_status () then
      Printexc.print_backtrace stderr;

    Log.error "%s" & match exc with
      | Failure msg -> msg
      | _ -> Printexc.to_string exc
