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
  ~synopsis:"Rebuild all the dependencies along with the project"
  Barbra.rebuild
and () = SubCommand.register & SubCommand.make
  ~name:"rebuild-deps"
  ~synopsis:"Rebuild all project dependencies"
  Barbra.rebuild_deps
and () = SubCommand.register & SubCommand.make
  ~name:"clean"
  ~synopsis:"Remove '_dep' directory with built dependencies"
  Barbra.cleanup

let () =
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


let () =
  ArgExt.parse ()
