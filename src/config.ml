
open Common
open Types

module List = ListLabels

module Keywords = struct
  let guess_archive s ~succ ~fail =
    let (_, ext) = String.split s "." in
    match ext with
      | "tar.gz"  -> succ `TarGz
      | "tar.bz2" -> succ `TarBzip2
      | "tar"     -> succ `Tar
      | _         -> fail ()

  let dep args = Scanf.sscanf args " %s %s %s " (fun name typ src ->
    let package = match String.lowercase typ with
      | "remote" ->
        guess_archive src
          ~succ:(fun x -> Remote (x,src))
          ~fail:(fun () -> Log.error "can't guess remote archive format: %S\n" typ)
      | "remote-tar-gz"  -> Remote (`TarGz, src)
      | "remote-tar-bz2" -> Remote (`TarBzip2, src)
      | "remote-tar"     -> Remote (`Tar, src)
      | "local" ->
        guess_archive src
          ~succ:(fun x -> Local (x, src))
          ~fail:(fun () -> Log.error "can't guess local archive format: %S\n" typ)
      | "local-tar-gz" -> Local (`TarGz, src)
      | "local-tar-bz2" -> Local (`TarBzip2, src)
      | "local-tar" -> Local (`Tar, src)
      | "local-dir" -> Local (`Directory, src)
      | "bundled-dir" -> Bundled (`Directory, src)
      | "bundled" ->
        guess_archive src
          ~succ:(fun x -> Bundled (x,src))
          ~fail:(fun () -> Log.error "can't guess bundle's archive format: %S\n" typ)
      | "bundled-tar" -> Bundled (`Tar, src)
      | "bundled-tar-gz" -> Bundled (`TarGz, src)
      | "bundled-tar-bz2" -> Bundled (`TarBzip2, src)
      | "svn" | "csv" | "hg" | "git" | "bzr" | "darcs" ->
        VCS (vcs_type_of_string typ, src)
      | _ -> Log.error "unsupported package type: %S when source = %S\n" typ src
    in (name, package)
  )
end

let parse_line_opt = function
  | ""   -> None
  | line ->
    let (keyword, args) = String.split line " " in
    some & match keyword with
      | "dep" -> Keywords.dep args
      | _     -> Log.error "Invalid keyword: %S" keyword

let check_dupes_v1 db =
  let sorted = List.sort
    ~cmp:(fun (n1, _p1) (n2, _p2) -> String.compare n1 n2) db
  in

  match sorted with
    | [] -> ()
    | (hn, _hp) :: t ->
      ignore & List.fold_left
        ~init:hn
        ~f:(fun hn (hn', _hp') ->
          if hn = hn' then
            Log.error "brb.conf: duplicate dependency %S" hn
          else
            hn'
        ) t

let parse_config_v1 s =
  s
  (* |> Stream.map (fun line -> let () = dbg "line: %s" line in line) *)
  |> Stream.map_filter parse_line_opt
  |> Stream.to_list
  |> fun r -> begin
       check_dupes_v1 r;
       r
     end

let get_config_version s = match Stream.next_opt s with
  | None -> Log.error "brb.conf empty!"
  | Some line ->
    try
      Scanf.sscanf (String.lowercase line) " version %s " identity
    with Scanf.Scan_failure _ ->
      Log.error "brb.conf: missing version!"

let parse_stream s =
  s
  |> Stream.map (String.strip ~chars:"\r\n")
  |> Stream.map_filter (fun line ->
    (* Note(superbobry): filter out *all* lines with comments, i. e.
       lines containing '#' character. This is probably too silly. *)
    if String.contains line '#' then None else Some line)
  |> fun s ->
    begin match get_config_version s with
      | "1" -> parse_config_v1 s
      | v   -> Log.error "brb.conf: unknown version %S" v
    end

let parse_string st =
  let lines = String.nsplit st "\n" in
  parse_stream (Stream.of_list lines)

let parse_config filename =
  filename
  |> Filew.stream_of_file_lines
  |> parse_stream
