
open Common
open Types

type t =
    {
      world : Recipe.world;
      deps  : dep list
    }

module Graph = Graph.Make(String)

let rec resolve_requirements world known =
  let missing = ref false in
  Hashtbl.iter (fun _ { requires; _ } ->
    List.iter requires ~f:(fun name ->
      if not (Hashtbl.mem known name) then begin
        missing := true;
        Hashtbl.add known name (world#resolve_any ~recipe:name)
      end
    )
  ) known;

  if !missing then
    resolve_requirements world known
  else
    known

let resolve_build_order known =
  let g = Graph.make (List.of_enum (Hashtbl.values known))
    ~f:(fun { name; requires; _ } -> (name, requires))
  in

  let build_order =
    try
      Graph.(topsort (transpose g))
    with Graph.Cycle_found _cycle ->
      Log.error "Cannot resolve cyclic dependencies!"
  in

  Log.info "Build order: %s" (String.concat ", " build_order);
  List.map ~f:(Hashtbl.find known) build_order

let resolve { deps; world } =
  let known = Hashtbl.create (List.length deps) in
  List.iter deps
    ~f:(fun ({ name; _ } as dep) ->
      if Hashtbl.mem known name then
        Log.error "Duplicate dependency %S in %S" name Global.brb_conf
      else
        Hashtbl.add known name dep;
    );

  {
    world;
    deps = known |> resolve_requirements world |> resolve_build_order
  }

module PH=ParserHelper

let rec from_file path =
  if not (Filew.is_file path) then
    Log.error "can't find %s in %S" Global.brb_conf (Filename.dirname path);

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
  match ParserHelper.smart_config Lexer.token lexbuf with
    | { Ast.version; _ } when version <> Global.version ->
      Log.error "Unsupported %S version %S, try %S?"
        Global.brb_conf
        version
        Global.version
    | { Ast.deps; Ast.repositories; _ } ->
      let world = new Recipe.world ~repositories in
      let deps  = List.map deps ~f:(fun ast ->
        let dep = Ast.to_dep ast in match dep.package with
          | Recipe location ->
            let ({ patches; flags; _ } as resolved) =
              world#resolve ~repository:location ~recipe:dep.name
            in

            (* FIXME(superbobry): what if both 'recipe' and 'brb.conf'
               have build or install commands? *)
            { resolved with
              patches = patches @ dep.patches;
              flags   = flags @ dep.flags
            }
          | (Remote _  | Local _ | Temporary _
                | Bundled _ | VCS _   | Installed) -> dep
      ) in { world; deps }
