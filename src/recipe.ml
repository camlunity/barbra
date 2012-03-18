
open StdLabels

open Common
open Types


exception Recipe_not_found of (string * string)
exception Recipe_invalid of string


class repository ~name ~path = object
  val recipes = lazy
    (Array.fold_right (Sys.readdir path)
      ~init:StringSet.empty
      ~f:StringSet.add)

  val name = name
  val path = if Filename.is_relative path then
      Global.base_dir </> path
    else
      path

  method resolve ~recipe =
    let recipes  = Lazy.force recipes in
    let abs_path = path </> recipe in

    if StringSet.mem recipe recipes && Filew.is_file abs_path then
      let ic = open_in abs_path in
      let lexbuf = Lexing.from_channel ic in
      try
        let dep = Ast.to_dep (Parser.recipe Lexer.token lexbuf) in
        Log.debug "Recipe %S is found in repository %S" recipe name;

        (* Note(superbobry): make sure the recipe has the same name
           as the filename; so for instance recipe 'lwt' should have
           'Dep lwt ...' line inside. *)
        if dep.name <> recipe then
          raise (Recipe_invalid recipe);

        (* Note(superbobry): all relative paths should be resolved,
           using repository root as base. *)
        { dep with
          patches = List.map ~f:(fun patch ->
            if Filename.is_relative patch then
              path </> patch
            else
              patch
          ) dep.patches }
      with exn ->
        begin
          close_in ic;

          match exn with
            | Parsing.Parse_error -> raise (Recipe_invalid recipe)
            | _ -> raise exn
        end
    else
      raise (Recipe_not_found (recipe, path))

  method iter ~f = StringSet.iter f (Lazy.force recipes)

  initializer
    try
      let stat = Unix.stat path in
      if stat.Unix.st_kind <> Unix.S_DIR then
        Log.error "Recipe repository %S at %S is not a directory"
          name path
    with
      | Unix.Unix_error (Unix.ENOENT, _, _) ->
          if name <> "default" then
            Log.error "Recipe repository %S at %S doesn't exist" name path
          else
            Log.error
              "Recipe repository %S at %S doesn't exist. Try running 'brb update'?"
              name path
      | Unix.Unix_error (Unix.EPERM, _, _)  ->
        Log.error
          "Recipe repository %S at %S is not readable; check permissions?"
          name path
end


class world ~repositories = object
  val repositories =
    let repos = if Sys.file_exists (Global.recipe_dir ())
      then (("default", Global.recipe_dir ()) :: repositories)
      else begin
        Log.info "Default recipes directory %s is absent. Skipping it" (Global.recipe_dir ());
        repositories
      end
    in
    List.fold_right repos ~init:StringMap.empty
    ~f:(fun (name, path) -> StringMap.add name (new repository ~name ~path))

  method resolve ~repository ~recipe =
    Log.debug "Resolving recipe %S in repository %S" recipe repository;

    try
      let r = StringMap.find repository repositories in r#resolve ~recipe
    with
      | Not_found ->
        Log.error "Repository %S is unknown" repository
      | Recipe_invalid _ ->
        Log.error "Recipe %S in repository %S has invalid syntax"
          recipe repository
      | Recipe_not_found (_, path) ->
        Log.error "Recipe %S not found in repository %S at %S"
          recipe repository path

  method resolve_any ~recipe =
    let dep_ref = ref None in
    StringMap.iter (fun repository r ->
      try
        dep_ref := Some (r#resolve ~recipe)
      with
        | Recipe_invalid _ ->
          Log.error "Recipe %S in repository %S has invalid syntax"
            recipe repository
        | Not_found | Recipe_not_found _ -> ()
    ) repositories;

    match !dep_ref with
      | Some dep -> dep
      | None ->
          Log.error "Recipe %S not found" recipe

  method iter ~f = StringMap.iter
    (fun repository r -> r#iter ~f:(f repository))
    repositories
end
