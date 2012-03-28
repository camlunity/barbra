open Common


let () =
  let only_deps = ref false and force_build = ref false and dont_clear_tmp = ref true
  and look_system = ref false in
  let specs = [("--only-deps", Arg.Set only_deps,
                "Act on dependencies only, ignoring project sources");
               ("--force", Arg.Set force_build,
                "Force build, even if the '_dep' directory already exists");
               ("--look-system-packs", Arg.Set look_system,
                "Don't install pakcages installed system-wide");
               ("--dont-clear-tmp", Arg.Set dont_clear_tmp,
                "Don't remove sources of successfully builded dependencies")]
  in

  let scmd = SubCommand.make
    ~name:"build"
    ~synopsis:"Build the project in the current directory"
    ~help:("Assumes that '_dep' directory doesn't exist or contains\n" ^
              "*already* built dependencies, listed in 'brb.conf'.")
    (fun () -> Barbra.build ~clear_tmp:(not !dont_clear_tmp) 
      ~look_system_packs:!look_system
      ~only_deps:!only_deps ~force_build:!force_build)
  in SubCommand.(register { scmd with specs })
and () = SubCommand.register & SubCommand.make
  ~name:"clean"
  ~synopsis:"Remove '_dep' directory with built dependencies"
  Barbra.cleanup
and () = SubCommand.register & SubCommand.make
  ~name:"update"
  ~synopsis:"Fetch the latest 'purse' full of fresh recipes!"
  ~help:"Clones or updates 'purse' repository in $HOME/.brb/recipes."
  Barbra.update
and () =
  let args = ref [] in
  let specs = [               
    ("--default-repo", Arg.String Global.set_recipe_dir,
     "Override default recipes directory (default is $HOME/.brb/recipes")
    ] in
  let cmd = SubCommand.make
    ~name:"install"
    ~synopsis:"Install one or more recipes to the '_dep' directory"
    ~usage:"recipe*"
    (fun () -> Barbra.install (List.rev !args))
  in

  SubCommand.(register {{ cmd with anon = fun arg -> args := arg :: !args } with specs})
and () = SubCommand.register & SubCommand.make
  ~name:"list"
  ~synopsis:"List all available recipes in all repositories"
  Barbra.list
and () =
  let args = ref [] in
  let cmd = SubCommand.make
    ~name:"run"
    ~synopsis:"Run a command in 'barbra' environment"
    ~help:("Uses '_dep/env.sh' to point some of 'ocamlfind' environmental\n" ^
           "variables to the '_dep' directory, which allows 'ocamlfind'  \n" ^
           "to use binaries and libraries, installed by 'brb'.")
    ~usage:"cmd [args*]"
    (fun () ->
      Barbra.run_with_env & List.fold_left
        ~f:(fun acc arg -> List.append acc (String.nsplit arg " "))
        ~init:[]
        !args)
  in

  SubCommand.(register { cmd with anon = fun arg -> args := arg :: !args })
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
