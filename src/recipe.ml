
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

  method resolve ~recipe =
    let recipes  = Lazy.force recipes in
    let abs_path = path </> recipe in

    if StringSet.mem recipe recipes && Filew.is_file abs_path then
      let ic = open_in abs_path in
      let lexbuf = Lexing.from_channel ic in
      try
        let dep = Ast.to_dep (Parser.recipe Lexer.token lexbuf) in
        Log.debug "Recipe %S is found in repository %S" recipe name;

        (* TODO(superbobry): make sure the recipe has the same name as
           the filename; so for instance recipe 'lwt' should have
           'Dep lwt ...' line inside *)
        dep
      with exn ->
        begin
          close_in ic;

          match exn with
            | Parsing.Parse_error -> raise (Recipe_invalid recipe)
            | _ -> raise exn
        end
    else
      raise (Recipe_not_found (recipe, path))

  initializer
    try
      let stat = Unix.stat path in
      if stat.Unix.st_kind <> Unix.S_DIR then
        Log.error "Recipe repository %S at %s is not a directory"
          name path
    with
      | Unix.Unix_error _ ->
        Log.error "Recipe repository %S at %s is not readable"
          name path
end


class world ~repositories = object
  val repositories = List.fold_right
    (("default", Global.recipe_dir) :: repositories)
    ~init:StringMap.empty
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
        Log.error "Recipe %S not found in repository %S at %s"
          recipe repository path
end
