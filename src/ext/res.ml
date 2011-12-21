type res 'a 'e =
  [= `Ok of 'a
  |  `Error of 'e
  ]
;

type m 'a = res 'a exn
;

value return r = `Ok r
;

value fail e = `Error e
;

value error e = `Error e
;

value bind f m =
  match m with
  [ `Ok a -> f a
  | (`Error _) as e -> e
  ]
;


value ( >>= ) m f = bind f m
;

value bind_rev = ( >>= )
;


value catch func handler =
  match func () with
  [ (`Ok _) as r -> r
  | `Error e -> handler e
  ]
;


value wrap1 f = fun a ->
  try `Ok (f a)
  with [ e -> `Error e ]
;

value wrap2 f = fun a b ->
  try `Ok (f a b)
  with [ e -> `Error e ]
;

value wrap3 f = fun a b c ->
  try `Ok (f a b c)
  with [ e -> `Error e ]
;

value wrap4 f = fun a b c d ->
  try `Ok (f a b c d)
  with [ e -> `Error e ]
;

value wrap5 f = fun a b c d e ->
  try `Ok (f a b c d e)
  with [ e' -> `Error e' ]
;

value catch_exn func =
  try
    func ()
  with
  [ e -> fail e ]
;

value catch_all f handler =
  catch (fun () -> catch_exn f) handler
;

value exn_res r =
  match r with
  [ `Ok x -> x
  | `Error e -> raise e
  ]
;

value map_err f r =
  match r with
  [ (`Ok _) as r -> r
  | `Error e -> `Error (f e)
  ]
;


value res_opterr oe =
  match oe with
  [ None -> `Ok ()
  | Some e -> `Error e
  ]
;


value res_optval ov =
  match ov with
  [ None -> `Error ()
  | Some v -> `Ok v
  ]
;


open Am_Ops
;

value res_exn func =
  catch_exn (return % func)
;


exception Foldres_exit
;

value (foldres_of_fold :
         ( ('a -> 'i ->     'a   ) -> 'a -> 'v ->     'a    ) ->
         ( ('a -> 'i -> res 'a 'e) -> 'a -> 'v -> res 'a 'e )
      )
fold =
  fun f init v ->
    let opt_err = ref None in
    let new_f a v =
      match f a v with
      [ `Ok new_a -> new_a
      | `Error e -> (opt_err.val := Some e; raise Foldres_exit)
      ]
    in
    try
      `Ok (fold new_f init v)
    with
    [ Foldres_exit ->
        match opt_err.val with
        [ None -> assert False
        | Some e -> `Error e
        ]
    ]
;


value rprintf fmt =
  Printf.ksprintf
    (fun str ->
       try
         return & output_string stdout str
       with
       [ e -> `Error e ]
    )
    fmt
;


value reprintf fmt =
  Printf.ksprintf
    (fun str ->
       try
         return & (output_string stderr str; flush stderr)
       with
       [ e -> `Error e ]
    )
    fmt
;


value wrap_with1 =
  fun with1 ->
    fun a f ->
      res_exn & fun () ->
        with1 a (exn_res % f)
;


value wrap_with3 =
  fun with3 ->
    fun a b c f ->
      res_exn & fun () ->
        with3 a b c (exn_res % f)
;


value list_map_all func lst =
  inner [] lst
  where rec inner rev_acc lst =
    match lst with
    [ [] -> return & List.rev rev_acc
    | [h :: t] ->
        match func h with
        [ `Ok x -> inner [x :: rev_acc] t
        | `Error e -> `Error (h, e)
        ]
    ]
;


value array_map_all func arr =
  let lst = Array.to_list arr in
  list_map_all func lst >>= fun res_lst ->
  return & Array.of_list res_lst
;


value list_fold_left_all func init lst =
  inner init lst
  where rec inner init lst =
    match lst with
    [ [] -> return init
    | [h :: t] ->
        match func init h with
        [ `Ok x -> inner x t
        | `Error e -> `Error (h, t, init, e)
        ]
    ]
;


value list_iter_all func lst =
  catch
    (fun () ->
  list_fold_left_all
    (fun () x -> ((func x) : res unit _))
    ()
    lst
    )
    (fun (h, t, (), e) -> fail (h, t, e))
;


value repeat n f a =
  inner 0 a
  where rec inner made a =
    if made >= n
    then
      `Ok a
    else
      match f a with
      [ `Ok a -> inner (made + 1) a
      | `Error e -> `Error (e, made)
      ]
;


(*
module Sys
 =
  struct

    include Sys;

    exception Command_failed of
      (string * [= `Error_code of int | `Exn of exn ])
    ;

    value () = Printexc.register_printer (fun
      [ Command_failed (cmd, e) ->
          Some (Printf.sprintf "command \"%s\" failed with %s"
            cmd
            (match e with
             [ `Error_code e ->
                  Printf.sprintf "error code %i" e
             | `Exn e ->
                  Printf.sprintf "exception: %s" (Printexc.to_string e)
             ]))
      | _ -> None
      ])
    ;

    value command_ok
     : string -> res unit exn
     = fun cmd ->
         try
           let c = Sys.command cmd in
           if c = 0
           then return ()
           else error (Command_failed cmd (`Error_code c))
         with
         [ e -> error (Command_failed cmd (`Exn e)) ]
    ;

  end
;
*)
