
open Common
open Types

let read_all_lines ch =
  Filew.channel_lines ch


let parse_line_opt s =
    if String.length s > 0 then
      some &
      Scanf.sscanf s " dep %s %s %s " (fun name typ src ->
        (* FIXME(superbobry): doesn't cover the new type schema! *)
        let package = match String.lowercase typ with
          | "remote-tar-gz" -> Remote (`TarGz, src)
          | "remote-tar-bz2" -> Remote (`TarBzip2, src)
          | "remote-tar" -> Remote (`Tar, src)
          | "local-tar-gz" -> Local (`TarGz, src)
          | "local-tar-bz2" -> Local (`TarBzip2, src)
          | "local-tar" -> Local (`Tar, src)
          | "local-dir" -> Local (`Directory, src)
          | "bundled-dir" -> Bundled (Persistent, `Directory, src)
          | "bundled-tar" -> Bundled (Persistent, `Tar, src)
          | "bundled-tar-gz" -> Bundled (Persistent, `TarGz, src)
          | "bundled-tar-bz2" -> Bundled (Persistent, `TarBzip2, src)
          | "svn" | "csv" | "hg" | "git" | "bzr" | "darcs" ->
            VCS (vcs_type_of_string typ, src)
          | _ -> failwith "unsupported delivery method: %S" typ
        in (name, package)
      )
    else
      None

let stream_filter : 'a . ('a -> bool) -> 'a Stream.t -> 'a Stream.t
 = fun pred s ->
     (* todo: implement directly *)
     Stream.map_filter (fun x -> if pred x then Some x else None) s

let line_means_something line =
  let len = String.length line in
  let rec inner i =
    if i = len
    then false
    else
      begin match line.[i] with
          '#' -> false
        | '\x20' | '\x09' | '\x0A' | '\x0D' -> inner (i + 1)
        | _ -> true
      end
  in
    inner 0

let filter_comments s =
  stream_filter line_means_something s

let parse_config_v1 s =
  s
  (* |> Stream.map (fun line -> let () = dbg "line: %s" line in line) *)
  |> Stream.map_filter parse_line_opt
  |> Stream.to_list

let remove_CR s =
  Stream.map
    (fun line ->
       let len = String.length line in
       if len > 0 && line.[len - 1] = '\x0D'
       then String.sub line 0 (len - 1)
       else line
    )
    s

let get_config_version s =
  begin match Stream.next_opt s with
      None -> failwith "empty config"
    | Some line ->
        try
          (* let () = dbg "get_config_version: line = %S" line in *)
          Scanf.sscanf (String.lowercase line) " version %s "
            (fun v -> v)
        with Scanf.Scan_failure _ ->
          failwith "first non-commented line of brb.conf should contain \
                    \"version N\" directive"
  end

let parse_stream s =
  s
  |> remove_CR
  |> filter_comments
  |> fun s ->
       begin match get_config_version s with
         "1" | _ -> parse_config_v1 s
       (* | v -> failwith "unknown config version %S" v *)
       end

let parse_config filename =
  filename
  |> Filew.stream_of_file_lines
  |> parse_stream

let parse_string st =
  let lines = String.nsplit st "\n" in
  parse_stream (Stream.of_list lines)
