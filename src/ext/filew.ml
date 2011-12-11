module Filename = Filename_new
;

exception Error of string and string and exn
  (* operation_name, file_name, exception *)
;

value error ~opn ~fn ~e =
  raise (Error opn fn e)
;

value with_file op opname cl func filename =
  let ch =
    try
      op filename
    with
    [ e -> error ~opn:opname ~fn:filename ~e ]
  in
  try
    let r = func ch in do
      { cl ch
      ; r
      }
  with
  [ e -> do
      { cl ch
      ; raise e
      }
  ]
;

value with_process_in cmd func =
  with_file
    Unix.open_process_in
    "with_process_in"
    Unix.close_process_in
    func
    cmd
;

value with_file_in_bin fn func =
  with_file open_in_bin "with_file_in_bin" close_in func fn
;

value with_file_out_bin fn func =
  with_file open_out_bin "with_file_out_bin" close_out func fn
;

value with_file_out_gen flags mode fn func =
  with_file (open_out_gen flags mode) "with_file_out_gen" close_out func fn
;


value is_directory d = 
  try
    Sys.file_exists d && Sys.is_directory d
  with
  [ e -> error ~opn:"is_directory" ~fn:d ~e ]
;


value is_file d = 
  try
    Sys.file_exists d && (not (Sys.is_directory d))
  with
  [ e -> error ~opn:"is_file" ~fn:d ~e ]
;


value remove_file filename =
  if is_file filename
  then
    try
      Sys.remove filename
    with
    [ e -> error ~opn:"remove_file" ~fn:filename ~e ]
  else
    failwith (Printf.sprintf "Filew.remove_file: not a file: %S" filename)
;


value with_temp_file_opened_bin ~cleanup ~temp_dir prefix suffix func =
  let (path_tmp, out_ch) =
    try
      Filename.open_temp_file ~mode:[Open_binary] ~temp_dir prefix suffix
    with
    [ e -> error
            ~opn:"with_temp_file_opened_bin/Filename.open_temp_file"
            ~fn:(Printf.sprintf "temp_dir=%S prefix=%S suffix=%S"
                   temp_dir prefix suffix
                )
            ~e
    ]
  in
  let finally () =
    ( try
        close_out out_ch
      with
      [ e -> error ~opn:"with_temp_file_opened_bin/close_out"
               ~fn:path_tmp ~e ]
    ; if cleanup
      then remove_file path_tmp
      else ()
    )
  in
  try
    let r = func path_tmp out_ch in do
      { finally ()
      ; r
      }
  with
  [ e -> do
      { finally ()
      ; raise e
      }
  ]
;


value input_line_opt ch =
  try Some (input_line ch)
  with
  [ End_of_file -> None ]
;


value fold_channel_lines func init ch =
  fold_channel_lines_inner init
  where rec fold_channel_lines_inner init =
  match input_line_opt ch with
  [ None ->
      init
  | Some line ->
      fold_channel_lines_inner (func init line)
  ]
;


value fold_file_lines func init filename =
  with_file_in_bin
    filename
    (fold_channel_lines func init)
;


value map_file_lines filename mapfunc =
  List.rev (
    fold_file_lines
      (fun rev_acc line -> [(mapfunc line) :: rev_acc])
      []
      filename
  )
;


value iter_file_lines filename func =
  fold_file_lines (fun () line -> func line) () filename
;


value channel_lines ch =
  List.rev
    (fold_channel_lines
       (fun rev_acc line -> [line :: rev_acc])
       []
       ch
    )
;


value file_lines fn =
  with_file_in_bin fn channel_lines
;


value slurp_ch ch =
  let strsz = 8192 in
  let buf = Buffer.create 1024
  and str = String.make strsz '\x00' in
  inner 0
  where rec inner cursz =
    let insz = input ch str 0 strsz in
    if insz = 0 then Buffer.contents buf else
    let newsz = cursz + insz in
    if newsz > Sys.max_string_length
    then
      failwith ( "Filew.slurp_ch: file is bigger than "
               ^ (string_of_int Sys.max_string_length)
               ^ " bytes"
               )
    else do
      { Buffer.add_substring buf str 0 insz
      ; inner newsz
      }
;


value slurp_bin filename = with_file_in_bin filename slurp_ch
   (* maybe replace with fixed buffer and with linking Unix for stat(). *)
;


value copy_channels ?(bufsz=4096) inch outch =
  if bufsz < 0 || bufsz > Sys.max_string_length
  then invalid_arg "Filew.copy_channels: bufsz"
  else
    let buf = String.make bufsz '\x00' in
    inner ()
    where rec inner () =
      let have_read = input inch buf 0 bufsz in
      if have_read = 0
      then ()
      else
        ( output outch buf 0 have_read
        ; inner ()
        )
;


value copy_file src dst =
  try
    with_file_in_bin src (fun inch ->
    with_file_out_bin dst (fun outch ->
    copy_channels inch outch
    ))
  with
  [ e -> failwith
           (Printf.sprintf
              "Filew.copy_file: can't copy \"%s\" to \"%s\": %s"
              src dst (Printexc.to_string e))
  ]
;


value try_create_dir dirname perm =
  try
    ( Unix.mkdir dirname perm
    ; assert (is_directory dirname)
    ; True
    )
  with
  [ Unix.Unix_error _ -> False ]
;


value temp_create_tries = 1000
;


value prng = Random.State.make_self_init ()
;


value create_temp_dir () =
  let tmp_root = Filename.temp_dir_name in
  inner temp_create_tries
  where rec inner tries_left =
    if tries_left <= 0
    then failwith "Filew.create_temp_dir: can't create temporary directory"
    else
      let dir = Printf.sprintf "filew%06i" (Random.State.int prng 1000000) in
      let path = Filename.concat tmp_root dir in
      if try_create_dir path 0o700
      then path
      else inner (tries_left - 1)
;


(* dumb name, but shell-style: -f, -d, -e *)
value is_exists d =
  Sys.file_exists d
;


value chdir dir =
  try
    Sys.chdir dir
  with
  [ e -> failwith (Printf.sprintf "Filew.chdir: can't chdir to %S: %s"
        dir
        (Printexc.to_string e)
      )
  ]
;


value with_cur_dir dir func =
  let old_dir = Sys.getcwd () in
  let finally () =
    chdir old_dir in
  try
    if not (is_directory dir)
    then
      failwith (Printf.sprintf
        "Filew.with_cur_dir: directory does not exist: %S"
        dir
        )
    else
      let () = chdir dir in
      let r = func () in
      let () = finally () in
      r
  with
  [ e -> ( finally () ; raise e ) ]
;


value forA arr func = Array.iter func arr
;


value readdir dir =
  try
    Sys.readdir dir
  with
  [ e -> error ~opn:"readdir" ~fn:dir ~e ]
;


value rec remove_directory_contents_rec dir =
  let entries = readdir dir in
  forA entries (fun entry ->
    let path = Filename.concat dir entry in
    if is_directory path
    then
      ( remove_directory_contents_rec path
      ; Unix.rmdir path
      )
    else
      ( Unix.unlink path
      )
  )
;


value remove_directory ~recursive dir =
  let fail msg = failwith ("Filew.remove_directory: " ^ msg) in
  if not (is_directory dir)
  then fail "not found or not a directory"
  else
    ( if recursive
      then
        remove_directory_contents_rec dir
      else
        ()
    ; Unix.rmdir dir
    )
;


value with_temp_dir func =
  let dir = create_temp_dir () in
  let finally () = remove_directory ~recursive:True dir in
  try
    let r = func dir in
    ( finally ()
    ; r
    )
  with
  [ e -> (finally () ; raise e) ]
;


value filename_NUL =
  if Sys.os_type = "Win32"
  then "NUL"
  else "/dev/null"
;


exception Exists
;


value file_line_exists filename pred =
  try
    ( iter_file_lines
        filename
        (fun line -> if pred line then raise Exists else ())
    ; False
    )
  with
  [ Exists -> True ]
;


value file_line_forall filename pred =
  not (file_line_exists filename (fun line -> not (pred line)))
;


value rename src dst =
  try
    Sys.rename src dst
  with
  [ e -> error ~opn:"rename" ~fn:(Printf.sprintf "src=%S dst=%S" src dst) ~e ]
;


value rename_to_tmp path_orig prefix suffix =
  let dir_orig = Filename.dirname path_orig in
  inner temp_create_tries
  where rec inner left =
    if left <= 0
    then failwith (Printf.sprintf
      "Filew.rename_to_tmp: can't rename file %S to temporary name \
       (directory %S, prefix %S, suffix %S)" path_orig dir_orig prefix suffix
      )
    else
      let fn_tmp = Printf.sprintf "%s%06i%s"
        prefix (Random.State.int prng 1000000) suffix in
      let path_tmp = Filename.concat dir_orig fn_tmp in
      if is_exists path_tmp
      then inner (left - 1)
      else
        ( rename path_orig path_tmp
        ; path_tmp
        )
;


value rename_opt src dst =
  try
    ( Sys.rename src dst
    ; None
    )
  with
  [ e -> Some e ]
;


value replace_file ?(justcreatenewfile=False) path_orig func =
  let dir_orig = Filename.dirname path_orig
  and fn_orig = Filename.basename path_orig in

  let (processing_res, path_tmp) =
(*
подумать, как ловить ошибку в with -- ибо тут явно она,
Sys_error при вызове replace_file.

0. ловить ли исключения в with-обёртке в try open_.. и try close_.. так,
   чтобы сообщать о них особым образом, типа failwith "Filew.with_..:
open_in_bin failed"?
1. использовать ли Res в Filew?
2. придумать ли шнягу для оборачивания ошибок, возникающих
только в with-обёртке?  (видимо заменой пользовательской функции
на что-то, следящее за исключениями?
"with1_catch thehandler with_file_in_bin path_orig & fun ..."
)
*)

    with_file_in_bin path_orig
    (fun in_ch ->
    with_temp_file_opened_bin
      ~cleanup:False
      ~temp_dir:dir_orig
      (fn_orig ^ ".") ".new"
    (fun path_tmp out_ch ->
    let res =
      try
        match func in_ch out_ch with
        [ None -> `Ok
        | Some e -> `Error e
        ]
      with
      [ e -> `Exn e ]
    in
      (res, path_tmp)
    ))
  in

  match processing_res with
  [ `Exn e -> (remove_file path_tmp ; raise e)
  | `Error e -> (remove_file path_tmp ; Some e)
  | `Ok ->
      (
        if justcreatenewfile
        then ()
        else
          let path_bak = rename_to_tmp path_orig (fn_orig ^ ".") ".bak" in
          let new_to_orig = rename_opt path_tmp path_orig in
          match new_to_orig with
          [ None ->
              remove_file path_bak
          | Some e ->
              ( rename path_bak path_orig
              ; raise e
              )
          ]
      ;
        None
      )
  ]
;


value copy_files srcs dst_dir =
  if not (is_directory dst_dir)
  then failwith (Printf.sprintf
    "Filew.copy_files: not a directory: %S" dst_dir)
  else
  let copied_files = ref [] in
  try
    List.iter
      (fun path ->
         let new_path = Filename.concat dst_dir (Filename.basename path) in
         let () = copy_file path new_path in
         copied_files.val := [new_path :: copied_files.val]
      )
      srcs
  with
  [ e ->
     ( List.iter remove_file copied_files.val
     ; raise e
     )
  ]
;


value stream_of_channel_lines_gen ~close inch =
  Stream.from
    (let inch_ref = ref (Some inch) in
     fun _ ->
       match inch_ref.val with
       [ None -> None
       | Some inch ->
           match input_line_opt inch with
           [ (Some _) as some_line -> some_line
           | None ->
               ( if close
                 then
                   ( close_in inch
                   ; inch_ref.val := None
                   )
                 else
                   ()
               ; None
               )
           ]
       ]
    )
;


value stream_of_channel_lines inch =
  stream_of_channel_lines_gen ~close:False inch
;


value stream_of_file_lines path =
  let inch =
    try
      open_in_bin path
    with
    [ e -> error ~opn:"stream_of_file_lines" ~fn:path ~e ]
  in
    stream_of_channel_lines_gen ~close:True inch
;
