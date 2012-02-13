%{
  open StdLabels
%}

%token VERSION
%token REPOSITORY
%token DEP
%token MAKE
%token FLAG
%token PATCH
%token EOF
%token <string> IDENT
%token <string> VALUE

%start config recipe
%type <Ast.ctxt> config
%type <Ast.dep> recipe

%%

config:
  | VERSION IDENT stmt_list EOF {
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
  | MAKE VALUE     {`Make $2}
  | FLAG VALUE     {`Flag $2}
  | PATCH VALUE    {`Patch $2}
;

stmt_list:
  | stmt_list stmt {$2 :: $1}
  |                {[]}
;

stmt:
  | REPOSITORY IDENT VALUE {`Repository ($2, $3)}
  | DEP IDENT IDENT VALUE meta_list {`Dep ($2, $3, $4, $5)}
  | IDENT {Log.error "brb.conf: invalid keyword %S" $1}
;

%%
