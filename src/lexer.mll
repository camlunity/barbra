{
  open Parser

  let lst =  [
    ("dep",  DEP);
    ("subdep", SUBDEP);
    ("endsubdep", ENDSUBDEP);
    ("build", BUILD);
    ("flag", FLAG);
    ("patch", PATCH);
    ("install", INSTALL);
    ("requires", REQUIRES);
    ("repository", REPOSITORY);
    ("version", VERSION);
    ("if", IF_MACRO);
    ("endif", ENDIF_MACRO);
    ("os_type", OSTYPE)
  ]
  let keywords = Hashtbl.create (List.length lst)
  let () = List.iter (fun (kwd, token) -> Hashtbl.add keywords kwd token) lst
}

rule token = parse
  | [' ' '\t']       {token lexbuf}
  | '#' [^'\r''\n']* {token lexbuf}
  | '\n'             {Lexing.new_line lexbuf; token lexbuf}
  | "\r\n"           {Lexing.new_line lexbuf; token lexbuf}
  | ','              {COMMA}
  | '('              {LBRA}
  | ')'              {RBRA}
  | eof              {EOF}
  | ['A'-'Z' 'a'-'z' '0'-'9' '%' '-' '_']+ as lxm {
    let lxm = String.lowercase lxm in
    try
      Hashtbl.find keywords lxm
    with Not_found -> IDENT(lxm)
  }
  | '"' ([^'"']+ as lxm) '"' {VALUE(lxm)}
