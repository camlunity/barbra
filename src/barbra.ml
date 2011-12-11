open Types
open Common
open Printf
open Source

let version = 1
and base_dir = "_dep"
and brb_conf = "brb.conf"  (* просто имя файла без путей *)


(* предполагаем, что текущая директория -- корень проекта *)
let install_from conf =
  List.iter
    (fun (pkg, typ) ->
      printf "I: Installing %S ..\n" pkg;

      let source = match typ with
        | HttpArchive _ -> new http_archive typ
        | _ -> failwith "unfetchable type for %S" pkg
      and dest_dir = Filename.concat base_dir pkg in

      makedirs dest_dir;
      ignore & source#fetch ~dest_dir
    )
    (Config.parse_config conf)


let install () =
  let conf = Filename.concat Filename.current_dir_name brb_conf in
  if Sys.file_exists conf then
    install_from conf
  else
    failwith "can't find brb.conf in %S" Filename.current_dir_name
