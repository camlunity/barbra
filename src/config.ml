
open Common
open Types

module List = ListLabels

let check_dupes deps =
  let sorted = List.sort
    ~cmp:(fun { name = name1; _ } { name = name2; _ } ->
      String.compare name1 name2) deps
  in

  match sorted with
    | [] -> ()
    | { name; _ } :: t ->
      ignore & List.fold_left
        ~init:name
        ~f:(fun name { name = name'; _ } ->
          if name = name' then
            Log.error "brb.conf: duplicate dependency %S" name
          else
            name'
        ) t

let rec from_file path =
  let ic = open_in path in
  try
    let deps = from_lexbuf (Lexing.from_channel ic) in
    close_in ic;
    deps
  with exc ->
    close_in ic;
    raise exc

and from_string s =
  from_lexbuf (Lexing.from_string s)

and from_lexbuf lexbuf =
  let fixup = function
    | { targets = []; _ } as p -> { p with targets = ["all"] }
    | p -> p
  in

  match Parser.main Lexer.token lexbuf with
    | (v, _) when v <> Global.version ->
      Log.error "brb.conf: unsupported version %S, try %S?"
        v
        Global.version
    | (_, deps) ->
      let deps = List.map deps ~f:(fun (name, package, metas) ->
        (* Note(superbobry): fold an assorted list of meta fields into
           three categories -- make targets, configure flags and patches;
           the order is preserved. *)
        let (targets, flags, patches) = List.fold_left metas
          ~init:([], [], [])
          ~f:(fun (ts, fs, ps) meta -> match meta with
            | `Make t  -> (t :: ts, fs, ps)
            | `Flag f  -> (ts, f :: fs, ps)
            | `Patch p -> (ts, fs, p :: ps)
          )
        in

        fixup { name; package; targets; flags; patches })
      in begin
        check_dupes deps;
        deps
      end
