(* what's now implemented with external filesystem-related utilities,
   but may be reimplemented in future (for example, with ocaml-fileutils) *)

open Common

let make_directories_p lst =
  exec_exn ("mkdir" :: "-p" :: lst)

let make_directory_p d =
  make_directories_p [d]

let remove_directory_recursive d =
  let () = exec_exn ["rm"; "-rf"; d] in
  let () = assert (not (Sys.file_exists d)) in
    (* there were cases when "rm -rf" exits with 0, but the directory
       still exists; we'll check for such cases. *)
  ()

let copy_directory_res ~src ~dst =
  let () = assert (Filew.is_directory src) in
  let () = assert (not (Sys.file_exists dst)) in
  exec ["cp"; "-R"; src; dst]
