%{
  open StdLabels
  type cond_type = [ `OsType of string ]
%}

%token VERSION
%token REPOSITORY DEP
%token FLAG PATCH REQUIRES INSTALL BUILD
%token COMMA OSTYPE
%token IF_MACRO ENDIF_MACRO
%token LBRA RBRA
%token EOF
%token <string> IDENT
%token <string> VALUE

%start config recipe cond
%type <Ast.ctxt> config
%type <Ast.dep> recipe
%type <[ `OsType of string ]> cond
%%

config:
  | VERSION VALUE stmt_list EOF {
    let open Ast in
    List.fold_left $3
    ~init:({ version = $2; deps = []; repositories = []})
    ~f:(fun ({ repositories; deps; _ } as ctxt) stmt ->
      match stmt with
        | `Repository r -> { ctxt with repositories = r :: repositories }
        | `Dep d -> { ctxt with deps = d :: deps }
    )
  }
;

recipe:
  | DEP IDENT IDENT VALUE meta_list {($2, $3, $4, $5)}
  | IDENT {Log.error "recipe: invalid keyword %S" $1}
;

meta_list:
  | meta_list meta {$2 :: $1}
  |                {[]}
;

meta:
  | BUILD VALUE       {`Build $2}
  | FLAG VALUE        {`Flag $2}
  | PATCH VALUE       {`Patch $2}
  | INSTALL VALUE     {`Install $2}
  | REQUIRES req_list {`Requires $2}
;

req_list:
  | req_list COMMA IDENT {$3 :: $1}
  | IDENT                {[$1]}
;

stmt_list:
  | stmt_list stmt {$2 :: $1}
  |                {[]}
;

stmt:
  | REPOSITORY VALUE VALUE {`Repository ($2, $3)}
  | DEP IDENT IDENT VALUE meta_list {`Dep ($2, $3, $4, $5)}
  | IDENT {Log.error "brb.conf: invalid keyword %S" $1}
;
cond:
  | LBRA cond RBRA { $2 }
  | OSTYPE LBRA IDENT RBRA { `OsType $3 }

%%


















