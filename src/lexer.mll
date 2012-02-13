{
  open Parser

  let keywords = Hashtbl.create 8
  let () = List.iter (fun (kwd, token) -> Hashtbl.add keywords kwd token) [
    ("dep",  DEP);
    ("make", MAKE);
    ("flag", FLAG);
    ("patch", PATCH);
    ("requires", REQUIRES);
    ("repository", REPOSITORY);
    ("version", VERSION)
  ]
}

rule token = parse
  | [' ' '\t']     {token lexbuf}
  | '#' [^'\n']*   {token lexbuf}
  | '\n'           {Lexing.new_line lexbuf; token lexbuf}
  | ","            {COMMA}
  | eof            {EOF}
  | ['A'-'Z' 'a'-'z' '0'-'9' '-' '_']+ as lxm {
    try
      Hashtbl.find keywords (String.lowercase lxm)
    with Not_found -> IDENT(lxm)
  }
  | '"' ([^'"']+ as lxm) '"' {VALUE(lxm)}
