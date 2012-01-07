%{
  open Common
  open Types

  let guess_archive s ~succ ~fail =
    let ext = Filename.check_suffix s in
    if ext ".tar.gz" then
      succ `TarGz
    else if ext ".tar.bz2" then
      succ `TarBzip2
    else if ext ".tar" then
      succ `Tar
    else
      fail ()
%}

%token VERSION
%token DEP
%token MAKE
%token FLAG
%token PATCH
%token EOF
%token <string> IDENT
%token <string> VALUE

%start main
%type <(Ast.ast_version * Ast.ast_dep list)> main

%%

main:
  | VERSION IDENT stmt_list EOF {($2, $3)}
;

meta_list:
  | meta_list meta {$2 :: $1}
  |                {[]}
;

meta:
  | MAKE VALUE  {`Make $2}
  | FLAG VALUE  {`Flag $2}
  | PATCH VALUE {`Patch $2}
;

stmt_list:
  | stmt_list stmt {$2 :: $1}
  |                {[]}
;

stmt:
  | DEP IDENT IDENT VALUE meta_list {
    let package = match String.lowercase $3 with
      | "remote" ->
        guess_archive $4
          ~succ:(fun x -> Remote (x, $4))
          ~fail:(fun () -> Log.error "can't guess remote archive format: %S\n" $3)
      | "remote-tar-gz"  -> Remote (`TarGz, $4)
      | "remote-tar-bz2" -> Remote (`TarBzip2, $4)
      | "remote-tar"     -> Remote (`Tar, $4)
      | "local" ->
        guess_archive $4
          ~succ:(fun x -> Local (x, $4))
          ~fail:(fun () -> Log.error "can't guess local archive format: %S\n" $3)
      | "local-tar-gz" -> Local (`TarGz, $4)
      | "local-tar-bz2" -> Local (`TarBzip2, $4)
      | "local-tar" -> Local (`Tar, $4)
      | "local-dir" -> Local (`Directory, $4)
      | "bundled-dir" -> Bundled (`Directory, $4)
      | "bundled" ->
        guess_archive $4
          ~succ:(fun x -> Bundled (x,$4))
          ~fail:(fun () -> Log.error "can't guess bundle's archive format: %S\n" $3)
      | "bundled-tar" -> Bundled (`Tar, $4)
      | "bundled-tar-gz" -> Bundled (`TarGz, $4)
      | "bundled-tar-bz2" -> Bundled (`TarBzip2, $4)
      | "svn" | "csv" | "hg" | "git" | "bzr" | "darcs" ->
        VCS (vcs_type_of_string $3, $4)
      | _ -> Log.error "unsupported package type: %S\n" $3
    in
    ($2, package, $5)
  }
;

%%
