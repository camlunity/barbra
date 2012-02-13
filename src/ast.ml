(** AST types and helpers. *)

open StdLabels
open Common
open Types

type meta = [ `Make of string
            | `Flag of string
            | `Patch of string ]

type dep = (string * string * string * meta list)
type repository = (string * string)

type ctxt =
    {
      version      : string;
      repositories : repository list;
      deps         : dep list
    }


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

let to_package (_name, source, location, _meta) = match source with
  | "remote" ->
    guess_archive location
      ~succ:(fun x -> Remote (x, location))
      ~fail:(fun () ->
        Log.error "can't guess remote archive format: %S\n" source)
  | "remote-tar-gz"  -> Remote (`TarGz, location)
  | "remote-tar-bz2" -> Remote (`TarBzip2, location)
  | "remote-tar"     -> Remote (`Tar, location)
  | "local" ->
    guess_archive location
      ~succ:(fun x -> Local ((x :> local_type), location))
      ~fail:(fun () ->
        Log.error "can't guess local archive format: %S\n" source)
  | "local-tar-gz" -> Local (`TarGz, location)
  | "local-tar-bz2" -> Local (`TarBzip2, location)
  | "local-tar" -> Local (`Tar, location)
  | "local-dir" -> Local (`Directory, location)
  | "bundled-dir" -> Bundled (`Directory, location)
  | "bundled" ->
    guess_archive location
      ~succ:(fun x -> Bundled ((x :> local_type), location))
      ~fail:(fun () ->
        Log.error "can't guess bundle's archive format: %S\n" source)
  | "bundled-tar" -> Bundled (`Tar, location)
  | "bundled-tar-gz" -> Bundled (`TarGz, location)
  | "bundled-tar-bz2" -> Bundled (`TarBzip2, location)
  | "svn" | "csv" | "hg" | "git" | "bzr" | "darcs" ->
    VCS (vcs_type_of_string source, location)
  | "recipe" -> Recipe location
  | _ -> Log.error "unsupported package type: %S\n" source

let to_dep ((name, _source, _location, metas) as ast) =
  (* Note(superbobry): fold an assorted list of meta fields into
     three categories -- make targets, configure flags and patches;
     the order is preserved. *)
  let (targets, flags, patches) = List.fold_left metas
    ~init:([], [], [])
    ~f:(fun (ts, fs, ps) meta -> match meta with
      | `Make t  -> (t :: ts, fs, ps)
      | `Flag f  ->
        (ts, (String.nsplit f " ") @ fs, ps)
      | `Patch p -> (ts, fs, p :: ps)
    )
  in

  {
    name;
    package = to_package ast;
    targets; flags; patches;
  }
