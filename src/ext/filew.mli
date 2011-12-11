exception Error of string and string and exn
  (* operation_name, file_name, exception *)
;

value with_file_in_bin : string -> (in_channel -> 'a) -> 'a
;

value with_file_out_bin : string -> (out_channel -> 'a) -> 'a
;

value with_file_out_gen :
  list Pervasives.open_flag ->
  int ->
  string ->
  (out_channel -> 'a) -> 'a
;

value with_process_in : string -> (in_channel -> 'a) -> 'a
;

value fold_channel_lines : ('a -> string -> 'a) -> 'a -> in_channel -> 'a
;

value fold_file_lines : ('a -> string -> 'a) -> 'a -> string -> 'a
;

value map_file_lines : string -> (string -> 'a) -> list 'a
;

value iter_file_lines : string -> (string -> unit) -> unit
;

(* channel won't be closed on 'end of stream' *)
value stream_of_channel_lines : in_channel -> Stream.t string
;

(* file will be closed on 'end of stream' *)
value stream_of_file_lines : string -> Stream.t string
;

value input_line_opt : in_channel -> option string
;

value slurp_bin : string -> string
;

value channel_lines : in_channel -> list string
;

value file_lines : string -> list string
;

value copy_channels : ?bufsz:int -> in_channel -> out_channel -> unit
;

(********************************************************************)

(* [copy_file src_path dst_path] *)
value copy_file : string -> string -> unit
;

(* [copy_files source_paths destination_directory]
   Removes copied files on failure.
*)
value copy_files : list string -> string -> unit
;

(* differs from Sys.is_directory: returns true when the directory exists,
   false otherwise.  No exceptions.
 *)
value is_directory : string -> bool
;

(* true if it exists and it is a file *)
value is_file : string -> bool
;

(* dumb name, but shell-style: -f, -d, -e *)
value is_exists : string -> bool
;

value remove_file : string -> unit
;

value remove_directory : ~recursive:bool -> string -> unit
;

(* [with_cur_dir dir func = chdir dir ; func () ; chdir back] *)
value with_cur_dir : string -> (unit -> 'a) -> 'a
;

(* [with_temp_dir func = make temp dir ; func its_name ; remove temp dir] *)
value with_temp_dir : (string -> 'a) -> 'a
;

value filename_NUL : string
;

value file_line_exists : string -> (string -> bool) -> bool
;

value file_line_forall : string -> (string -> bool) -> bool
;

(* if the function returns [Some e], then new file is not created
   and [Some e] is returned.  Otherwise (if [None]), file is replaced
   with new created file, written to out_channel.
   When the user function or system functions (rename, remove) raise
   exception, temporary files are deleted and exception is re-raised
   again.
   Channels are opened and closed by [replace_file].
 *)
value replace_file : ?justcreatenewfile:bool -> string ->
                     (in_channel -> out_channel -> option 'e) ->
                     option 'e
;

(* [rename_to_tmp path_orig prefix suffix] *)
value rename_to_tmp : string -> string -> string -> string
;
