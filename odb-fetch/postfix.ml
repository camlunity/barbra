
let all_pkgs = 
      List.map (fun wr ->
        try deps_uri "00list" wr |> Http.get_contents
        with Failure _ -> printf "%s is unavailable or not a valid repository\n\n" wr; ""
      ) webroots |> List.hd |> Str.split (Str.regexp " ") |> List.map to_pkg

let print_barbra () = 
    let pkgs =
      List.map (fun wr ->
        try deps_uri "00list" wr |> Http.get_contents
        with Failure _ -> printf "%s is unavailable or not a valid repository\n\n" wr; ""
      ) webroots |> String.concat " "
    in
    let find_opt x lst = 
      try
        lst |> List.find (fun (y,_) -> y=x) |> snd |> (fun x -> Some x)
      with Not_found -> None in
    let to_barbra ch {id; props} = 
      let tarball = props |> List.find (fun (x,_) -> x="tarball") |> snd in
      let () = fprintf ch "\nDep %s remote \"%s%s/%s\"\n" id (List.hd webroots) !repository tarball in
      let remove_version s = 
        try  String.sub s 0 (String.index s '(')
        with Not_found -> s in
      let () = match find_opt "deps" props with
        | None
        | Some "" -> ()
        | Some x -> fprintf ch "\tRequires %s\n" (remove_version x)
      in
      ()
    in
    let pkgs = Str.split (Str.regexp " +") pkgs in
    (match pkgs with
    | [] -> print_endline "No packages available"
    | hd :: tl -> (* Remove duplicate entries (inefficiently) *)
        let pkgs = List.fold_left (fun accu p -> if List.mem p accu then accu else p :: accu) [hd] tl in
(*        print_string "Available packages from oasis:";
        List.iter (printf " %s") (List.rev pkgs); *)
        let () = print_endline "Showing barbra info" in
        let ch = open_out "odb.recipes" in
        Printf.fprintf ch "Version \"0.2\"\nRepository \"local\" \"_recipes\"\n";
        let () = List.iter (fun name -> to_barbra ch (to_pkg name)) (List.rev pkgs) in
        let () = close_out ch in
        print_newline ()
    );
    print_newline ()

let () = print_barbra ()













