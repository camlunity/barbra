open Format

module List = ListLabels

let pp_print_string_spaced fmt =
  String.iter (function
    | ' ' | '\n' -> Format.pp_print_space fmt ()
    | c -> Format.pp_print_char fmt c)

let pp_print_list pp_elem sep fmt = function
  | [] -> ()
  | hd :: tl ->
    pp_elem fmt hd;
    List.iter
      ~f:(fun e -> fprintf fmt sep; pp_elem fmt e)
      tl

let pp_print_justified size fmt s =
  let tmp = String.make size ' ' in
  String.blit s 0 tmp 0 (String.length s);
  pp_print_string fmt tmp

let pp_print_underlined c fmt s =
  pp_print_string fmt s;
  pp_print_newline fmt ();
  pp_print_string fmt (String.make (String.length s) c)

let pp_print_endblock fmt () =
  pp_print_newline fmt ();
  pp_print_newline fmt ()

let pp_print_para fmt s =
  pp_open_box fmt 0;
  pp_print_string_spaced fmt s;
  pp_close_box fmt ();
  pp_print_endblock fmt ()

let pp_print_output_def size fmt (term, def) =
  pp_print_string fmt "  ";
  pp_print_justified size fmt term;
  pp_print_string fmt "  ";
  pp_open_box fmt 0;
  pp_print_string_spaced fmt def;
  pp_close_box fmt ();
  pp_print_newline fmt ()
