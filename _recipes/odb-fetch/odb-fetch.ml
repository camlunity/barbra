open Printf
let (|>) x f = f x
let () =
  Sys.command "curl -O https://raw.github.com/thelema/odb/master/odb.ml" |> ignore;
  let _ = 
    sprintf "echo  \"let () = Unix.chdir \\\"%s\\\";;\n\" >> odb.ml" (Sys.getcwd ()) |> Sys.command in
  let _ = sprintf "cat postfix.ml >> odb.ml" |> Sys.command in
  let _ = "ocaml odb.ml" |> Sys.command in
  print_endline "See output in odb.recipes"
    











