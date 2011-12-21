module Stream
 =
  struct

    include Stream;

    value input_line_opt in_ch =
      try Some (input_line in_ch) with
      [ End_of_file -> None ]
    ;

(*
    value lines_of_channel in_ch =
      from
        (fun _ ->
           input_line_opt in_ch
        )
    ;
*)

    value next_opt s =
      match peek s with
      [ None -> None
      | (Some _) as some_x ->
          ( Stream.junk s
          ; some_x
          )
      ]
    ;

    value map f s = Stream.from (fun _ ->
      match next_opt s with
      [ None -> None
      | Some x -> Some (f x)
      ]
     )
    ;

    value map_filter
(*      : ! 'a 'b . ('a -> option 'b) -> t 'a -> t 'b *)
     = fun f s -> Stream.from inner
      where rec inner _streamarg =
        match next_opt s with
        [ None -> None
        | Some x ->
            match f x with
            [ None -> inner _streamarg
            | some_v -> some_v
            ]
        ]
    ;

    value is_empty s =
      try (Stream.empty s; True)
      with [ Stream.Failure -> False ]
    ;

    value rec njunk n s =
      if n <= 0
      then ()
      else (junk s; njunk (n - 1) s)
    ;


    (* leave no more than n last items of stream s, junk others. *)

    value keep_last n s =
      if n < 1 then invalid_arg "Am_Stream.last" else
      loop ()
      where rec loop () =
        let l = List.length (npeek (n + 1) s) in
        if l <= n
        then ()
        else (junk s; loop ())
    ;

    value to_list s =
      inner []
      where rec inner rev_acc =
        match next_opt s with
        [ None -> List.rev rev_acc
        | Some x -> inner [x :: rev_acc]
        ]
    ;

    value pervasives_eq a b = (Pervasives.compare a b = 0)
    ;

    value is_prefix ?(eq=pervasives_eq) ~prefix stream =
      let pref_len = List.length prefix in
      let spref = npeek pref_len stream in
         List.length spref = pref_len
      && List.for_all2 eq prefix spref
    ;

  end
;
