
open StdLabels

open Common
open Types

module G = Global

let check_dupes deps =
  let sorted = List.sort deps
    ~cmp:(fun { name = name1; _ } { name = name2; _ } ->
      String.compare name1 name2)
  in  match sorted with
    | [] -> ()
    | { name; _ } :: t ->
      ignore & List.fold_left t
        ~init:name
        ~f:(fun name { name = name'; _ } ->
          if name = name' then
            Log.error "Duplicate dependency %S in %S" name G.brb_conf
          else
            name'
        )

let rec from_file path =
  let ic = open_in path in
  try
    from_lexbuf (Lexing.from_channel ic)
  with
    | exn ->
      close_in ic;
      raise exn

and from_string s =
  from_lexbuf (Lexing.from_string s)

and from_lexbuf lexbuf =
  match Parser.config Lexer.token lexbuf with
    | { Ast.version; _ } when version <> G.version ->
      Log.error "Unsupported %S version %S, try %S?"
        G.brb_conf
        version
        Global.version
    | { Ast.deps; Ast.repositories; _ } ->
      let world = new Recipe.world ~repositories in
      let deps  = List.map deps ~f:(fun ast ->
        let dep = Ast.to_dep ast in match dep.package with
          | Recipe location ->
            let ({ targets; patches; flags; _ } as resolved) =
              world#resolve ~repository:location ~recipe:dep.name
            in

            { resolved with
              targets = targets @ dep.targets;
              patches = patches @ dep.patches;
              flags   = flags @ dep.flags
            }
          | (Remote _  | Local _ | Temporary _
                | Bundled _ | VCS _   | Installed) -> dep
      ) in

      begin
        check_dupes deps;
        deps
      end
