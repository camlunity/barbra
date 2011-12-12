open Types
open Common
open Printf
open Source

let version = 1
and base_dir = "_dep"
and brb_conf = "brb.conf"  (* просто имя файла без путей *)


(* предполагаем, что текущая директория -- корень проекта *)
let install_from conf =
  let src_dir = Filename.concat base_dir "src" in
  List.iter
    (fun (pkg, typ) ->
      printf "I: Installing %S ..\n" pkg;

      let source = match typ with
        | Remote (archive_type, uri) ->
          new remote_archive uri archive_type
        | _ -> failwith "unfetchable type for %S" pkg
      and dest_dir = Filename.concat src_dir pkg in

      if source#is_available () then (
        makedirs dest_dir;
        ignore & source#fetch ~dest_dir
      ) else
        failwith "fixme: how to report this?"
    )
    (Config.parse_config conf)


let install () =
  let conf = Filename.concat Filename.current_dir_name brb_conf in
  if Sys.file_exists conf then
    install_from conf
  else
    failwith "can't find brb.conf in %S" Filename.current_dir_name
