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

let generic_message ~channel ~lvl msg = match lvl with
  (* Note(superbobry): make sure our verbosity level matches the
     level of the message, being logged (see above for numbers). *)
  | `Debug   when !verbosity < 3 -> ()
  | `Info    when !verbosity < 2 -> ()
  | `Warning when !verbosity < 1 -> ()
  | _ ->
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
