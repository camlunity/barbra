(* для проверки компилируемости: *)
open Types
open Common
open Printf

module Q =
  struct
    open Config
    open Install
  end


let version = 1
and base_dir = "_dep"
and brb_conf = "brb.conf"  (* просто имя файла без путей *)


(* предполагаем, что текущая директория -- корень проекта *)
let install_from conf =
  let db = Config.parse_config conf in
  let () =
    List.iter
      (fun (pkg, _wher) ->
         printf "we will install: %S\n%!" pkg
      )
      db
  in
    failwith "тут неплохо бы сгенерировать из _wher что-то для Install.*"


let install () =
  let conf = Filename.concat Filename.current_dir_name brb_conf in
  if Sys.file_exists conf
  then install_from conf
  else failwith "can't find brb.conf at %S" conf
