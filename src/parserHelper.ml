open Parser 

let eval_cond cond = 
  let open Common in
  match cond with
    | `OsType name ->
        begin
          match (String.lowercase name, Common.OSInfo.family) with
            | ("all",_) -> true
            | ("otherunix",OSInfo.OtherUnix) 
            | ("linux",OSInfo.Linux)
            | ("darwin",OSInfo.Darwin)
            | ("win32",OSInfo.Win32)
            | ("cygwin",OSInfo.Cygwin)
            | ("freebsd",OSInfo.FreeBSD) -> true
            | _ -> false
        end

let my_tokenizer (func: Lexing.lexbuf -> token) =
  let last_defined = ref [] in (* stack for defined macroses *)
  let good_code = ref true in
  let rec tokenizer lexbuf = 
    match func lexbuf with
      | IF_MACRO ->
          Log.info "IF_MACRO found";
          let cond = eval_cond (Parser.cond Lexer.token lexbuf) in
          good_code := !good_code && cond;
          last_defined := "x" :: !last_defined;
          tokenizer lexbuf
      | ENDIF_MACRO ->
          if !last_defined = [] 
          then Log.error "closing unopened if macro. stack is (%s)" (String.concat "," !last_defined)
          else (last_defined := List.tl !last_defined; tokenizer lexbuf)
      | x ->
          Log.info "stack is (%s)" (String.concat "," !last_defined);
          if !good_code then x
          else tokenizer lexbuf
  in
  tokenizer

let smart_parser hof (func: Lexing.lexbuf -> token) lexbuf =
  hof (my_tokenizer func) lexbuf

let smart_config = smart_parser config

let smart_recipe = smart_parser recipe
  
  




