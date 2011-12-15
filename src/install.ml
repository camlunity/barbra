open Common
open Types
open Global

module G = Global


let getenv ?(default="") env_name =
  try Unix.getenv env_name with Not_found -> default

let prepend_path what_to_prepend old_path =
   sprintf "%s%s%s"
     what_to_prepend
     (if old_path = "" then "" else ":")
     old_path

let line_of_process cmdline =
  Filew.with_process_in cmdline & fun inch ->
  Filew.input_line_opt inch

module WithCombs = struct
  open WithM
  open Res
  open WithRes

(* variable that was not set will be restored to "". *)
let with_env =
    { cons = (fun (env_name, new_val) ->
        let old_val = getenv env_name in
        let () = Unix.putenv env_name new_val in
        return (env_name, old_val)
      )
    ; fin = (fun (env_name, old_val) ->
        let () = Unix.putenv env_name old_val in
        return ()
      )
    }

let with_env_prepended =
  premap
    (fun (name, what_to_prepend) ->
       let old = getenv name in
       let new_var = prepend_path what_to_prepend old in
       (name, new_var)
    )
    with_env

end

open WithCombs


(*
let generate_findlib_configs () : unit =
  let etc_dir = G.etc_dir in
  let dest_dir = G.lib_dir </> "sit#e-lib" in
  let new_ld_conf = G.lib_dir </> "ld.conf" in
  let () = assert (Sys.is_directory etc_dir) in
  let path =
    let old_path = getenv_or_empty "OCAMLPATH" in
    let old_path =
      if old_path <> ""
      then
        old_path
      else
        try
          match line_of_process "ocamlfind printconf path" with
          | None -> ""
          | Some line -> line
        with
          Unix.Unix_error _ -> ""
    in
      prepend_path dest_dir old_path
  in
  let () =
    Filew.with_file_out_bin (etc_dir </> "findlib.conf") & fun outch ->
    List.iter
      (fun (k, v) -> fprintf outch "%s = %S\n%!" k v)
      [ ("path", path)
      ; ("destdir", dest_dir)
      ]
  in
  let () =
    begin match line_of_process "ocamlfind printconf ldconf" with
    | None -> ()
    | Some old_ld_conf ->
        Filew.copy_file old_ld_conf new_ld_conf
    end
  in
    ()
*)


let the_env =
  [ (`Prepend, "OCAMLPATH", G.lib_dir)
  ; (`Prepend, "PATH", G.bin_dir)
  ; (`Set, "OCAMLFIND_DESTDIR", G.lib_dir)
  ; (`Prepend, "CAML_LD_LIBRARY_PATH", G.stublibs_dir)
  ; (`Set, "OCAMLFIND_LDCONF", "ignore")
  ]


let do_write_env fn =
  Filew.with_file_out_bin fn & fun outch ->
  List.iter
    (let set n v = fprintf outch "export %s=\"%s\"\n" n v in
     function
     | (`Set, n, v) -> set n v
     | (`Prepend, n, v) ->
         ( fprintf outch "test -z \"$%s\" || %s=\":$%s\"\n" n n n
         ; set n (sprintf "%s$%s" v n)
         )
    )
    the_env

let lazy_write_env = lazy (do_write_env Global.env_sh)

let write_env () = Lazy.force lazy_write_env


let withres_env =
  let open WithM.WithRes in
  let open Res in
  sequence
    { cons = begin function
        | (`Prepend, n, v) ->
            with_env_prepended.cons (n, v) >>= fun r ->
            return (`Prepend, r)
        | (`Set, n, v) ->
            with_env.cons (n, v) >>= fun r ->
            return (`Set, r)
      end
    ; fin = begin function
        | (`Prepend, old_env) -> with_env_prepended.fin old_env
        | (`Set, old_env) -> with_env.fin old_env
      end
    }


let run_with_env cmd =
  let open WithM in
  let open Res in
  WithRes.bindres withres_env the_env & fun _old_env ->
  exec cmd


let makefile : install_type = object
  method install ~source_dir =
    let open WithM in
    let open Res in begin
      Global.create_dirs ();
      write_env ();
      Log.info "Starting Makefile build";

      WithRes.bindres WithRes.with_sys_chdir source_dir & fun _old_path ->
      WithRes.bindres withres_env the_env & fun _old_env ->
        Unix.(
          if Sys.file_exists "configure" then
            if (stat "configure").st_perm land 0o100 <> 0 then
              exec ["./configure"]
            else
              exec ["sh" ; "./configure"]
          else
            return ()) >>= fun () ->
        let make = getenv ~default:"make" "MAKE" in
        exec [make] >>= fun () ->
        exec [make; "install"]
    end
end
