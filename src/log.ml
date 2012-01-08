open Printf

type level =
  [ `Debug    (* 3 *)
  | `Info     (* 2 (default) *)
  | `Warning  (* 1 *)
  | `Error    (* 0 *)
  ]

let char_of_level = function
  | `Debug   -> 'D'
  | `Info    -> 'I'
  | `Warning -> 'W'
  | `Error   -> 'E'

let verbosity = ref 2

(* TODO(bobry): add verbosity & debug flags? *)
let generic_message ~channel ~lvl msg =
  fprintf channel "%c: %s\n" (char_of_level lvl) msg;
  flush channel

let info fmt =
  ksprintf (generic_message ~channel:stdout ~lvl:`Info) fmt
and warn fmt =
  ksprintf (generic_message ~channel:stdout ~lvl:`Warning) fmt
and debug fmt =
  ksprintf (generic_message ~channel:stderr ~lvl:`Debug) fmt
and error fmt = ksprintf (fun msg ->
  generic_message ~channel:stderr ~lvl:`Error msg; exit 1) fmt
