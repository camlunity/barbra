open Printf

type level =
  [ `Debug
  | `Info
  | `Warning
  | `Error
  ]

let char_of_level = function
  | `Debug   -> 'D'
  | `Info    -> 'I'
  | `Warning -> 'W'
  | `Error   -> 'E'

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
