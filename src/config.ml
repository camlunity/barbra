
open Common
open Types


let read_all_lines ch =
  Filew.channel_lines ch


let parse_line_opt s =
    if String.length s > 0 then
      some &
      Scanf.sscanf s "dep %s %s %s" (fun name typ src ->
        match String.lowercase typ with
          | "local"       -> (name,Local)
          | "http-tar-gz" -> (name,HttpArchive (src,TarGz))
          | "fs-tar"      -> (name,FsArchive   (src,Tar))
          | "svn" | "hg"
          | "git" | "bzr" -> (name,VCS (src,vcs_type_of_string typ) )
          | "fs-src"      -> (name,FsSrc src)
          | _             -> failwith "unsupported delivery method"
      )
    else
      None

let parse_stream s =
  s
  |> Stream.map_filter parse_line_opt
  |> Stream.to_list

let parse_config filename =
  filename
  |> Filew.stream_of_file_lines
  |> parse_stream

let parse_string st =
  let lines = String.nsplit st "\n" in
  parse_stream (Stream.of_list lines)
