open Format
module List = ListLabels

open Common
open SubCommand
open FormatExt

type help_extent = [ `NoSubCommand
                   | `SubCommand of string
                   | `AllSubCommands
                   ]

let specs = [
  ("--quiet",
   Arg.Unit (fun () -> Log.verbosity := 0),
   "Run quietly");
  ("--debug",
   Arg.Unit (fun () -> Log.verbosity := 3),
   "Output debug messages");
  ("--version",
   Arg.Unit (fun () -> printf "%s\n" Barbra.version; exit 0),
   "Output version information and exit")
]

let usage_msg = "brb [global-options*] subcommand [subcommand-options*]"


(* Pretty printers. *)

let pp_print_specs fmt specs =
  let help_specs = List.rev_append
    (List.rev_map ~f:(fun (name, _, help) -> (name, help)) specs)
    ["--help", "Display this list of options"]
  in

  let size = List.fold_left
    ~init:0
    ~f:(fun acc (term, _) -> max acc (String.length term))
    help_specs
  in

  pp_print_list (pp_print_output_def size) "" fmt help_specs;
  pp_print_newline fmt ()

let pp_print_cmd fmt { name; help; usage; specs; _ } =
  pp_print_underlined '-' fmt (sprintf "Subcommand %s" name);
  pp_print_endblock fmt ();

  pp_print_string fmt help;
  pp_print_endblock fmt ();

  fprintf fmt ("Usage: brb [global-options*] %s %s") name usage;
  pp_print_endblock fmt ();

  match specs with
    | [] -> ()
    | _  ->
      pp_print_para fmt "Options: ";
      pp_print_specs fmt specs

let pp_print_cmds fmt () =
  let size = SubCommand.fold
    ~init:0
    ~f:(fun name _ acc -> max acc (String.length name))
  in

  pp_print_para fmt "Available subcommands:";
  SubCommand.fold ~init:() ~f:(fun name { synopsis; _ } () ->
    ignore & pp_print_output_def size fmt (name, synopsis)
  );
  pp_print_newline fmt ()

let pp_print_help hext fmt () =
  pp_print_string fmt usage_msg;
  pp_print_endblock fmt ();

  pp_print_specs fmt specs;
  pp_print_cmds fmt ();

  match hext with
    | `NoSubCommand -> ()
    | `SubCommand name ->
      pp_print_cmd fmt (SubCommand.find name)
    | `AllSubCommands ->
      SubCommand.fold
        ~init:()
        ~f:(fun _ cmd () -> pp_print_cmd fmt cmd)


(* Hardcore subcommand parsing; solely taken from OASIS. *)

let parse () =
  let pos = ref 0 in
  let cmd = ref & SubCommand.make
    ~name:"none"
    ~synopsis:""
    (fun () -> Log.error "No subcommand defined, call 'brb --help' for help")
  and cmd_args = ref [||] in

  let set_cmd s =
    cmd := SubCommand.find s;
    cmd_args := Array.sub Sys.argv !pos ((Array.length Sys.argv) - !pos);
    pos := !pos + Array.length !cmd_args
  in

  let handle_error exc hext =
    let get_bad txt =
      match String.nsplit txt "\n" with
        | [] -> "Unknown error on the command line"
        | fst :: _ -> fst
    in match exc with
      | Arg.Bad txt ->
        pp_print_help hext err_formatter ();
        prerr_endline (get_bad txt);
        exit 2
      | Arg.Help _txt ->
        pp_print_help hext std_formatter ();
        exit 0
      | _ ->
        raise exc
  in

  (* Parse global opions and set current subcommand. *)
  begin
    try
      Arg.parse_argv
        ~current:pos
        Sys.argv
        specs
        set_cmd
        usage_msg
    with exc ->
      handle_error exc `NoSubCommand
  end;

  (* Parse subcommand's options and execute it. *)
  begin
    try
      Arg.parse_argv
        ~current:(ref 0)
        !cmd_args
        (Arg.align !cmd.specs)
        !cmd.anon
        (sprintf "Subcommand %S options:\n" !cmd.name)
    with exc ->
      handle_error exc (`SubCommand !cmd.name)
  end;

  !cmd.main ()
