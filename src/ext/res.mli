type res 'a 'e =
  [= `Ok of 'a
  |  `Error of 'e
  ]
;

type m 'a = res 'a exn
;

value return : 'a -> res 'a 'e
;

value fail : 'e -> res 'a 'e
;

value error : exn -> res 'a exn
;

value bind : ('a -> res 'b 'e) -> res 'a 'e -> res 'b 'e
;

value bind_rev : res 'a 'e -> ('a -> res 'b 'e) -> res 'b 'e
;

value ( >>= ) : res 'a 'e -> ('a -> res 'b 'e) -> res 'b 'e
;

value catch : (unit -> res 'a 'e1) -> ('e1 -> res 'a 'e2) -> res 'a 'e2
;

value wrap1 : ('a -> 'z)
           -> ('a -> res 'z exn)
;

value wrap2 : ('a -> 'b -> 'z)
           -> ('a -> 'b -> res 'z exn)
;

value wrap3 : ('a -> 'b -> 'c -> 'z)
           -> ('a -> 'b -> 'c -> res 'z exn)
;

value wrap4 : ('a -> 'b -> 'c -> 'd -> 'z)
           -> ('a -> 'b -> 'c -> 'd -> res 'z exn)
;

value wrap5 : ('a -> 'b -> 'c -> 'd -> 'e -> 'z)
           -> ('a -> 'b -> 'c -> 'd -> 'e -> res 'z exn)
;

value res_exn : (unit -> 'a) -> res 'a exn
;

value res_opterr : option 'e -> res unit 'e
;

value res_optval : option 'r -> res 'r unit
;

(* Ловит реальные исключения, доводя их "fail exn".
   Отличие от res_exn в том, что тут функция возвращает уже res.
   "res_exn f" = "catch_exn (return % f)"
   = "catch_exn (fun () -> return (f ()))"
 *)
value catch_exn : (unit -> res 'a exn) -> res 'a exn
;

(* Ловит как реальные исключения, так и res-ошибки (обязанные иметь
   тип exn), обрабатывает. *)
value catch_all : (unit -> res 'a exn) -> (exn -> res 'a exn) -> res 'a exn
;

value exn_res : res 'a exn -> 'a
;

value map_err : ('e1 -> 'e2) -> res 'a 'e1 -> res 'a 'e2
;

value foldres_of_fold :
        ( ('a -> 'i ->     'a   ) -> 'a -> 'v ->     'a    ) ->
        ( ('a -> 'i -> res 'a 'e) -> 'a -> 'v -> res 'a 'e )
;

(*
value rprintf : Pervasives.format 'a Pervasives.out_channel unit -> res 'a exn
;
*)

value rprintf :
  Pervasives.format4
  'a unit string (res unit exn) -> 'a
;

value reprintf :
  Pervasives.format4
  'a unit string (res unit exn) -> 'a
;

value wrap_with1 :
   ( 'a -> ('r ->     'z    ) ->     'z     ) ->
   ( 'a -> ('r -> res 'z exn) -> res 'z exn )
;

value wrap_with3 :
   ( 'a -> 'b -> 'c -> ('r ->     'z    ) ->     'z     ) ->
   ( 'a -> 'b -> 'c -> ('r -> res 'z exn) -> res 'z exn )
;


(* sequential. *)
value list_map_all :
   ( 'a -> res 'b 'e ) -> list 'a -> res (list 'b) ('a * 'e)
;

value array_map_all :
   ( 'a -> res 'b 'e ) -> array 'a -> res (array 'b) ('a * 'e)
;


value list_fold_left_all :
   ( 'a -> 'i -> res 'a 'e ) -> 'a -> list 'i
   -> res 'a ('i * list 'i * 'a * 'e)
;


value list_iter_all :
   ( 'a -> res unit 'e ) -> list 'a -> res unit ('a * list 'a * 'e)
;


(* error contains: (the_occured_error, count_of_repeats_made) *)
value repeat : int -> ( 'a -> res 'a 'e ) -> 'a -> res 'a ('e * int)
;


module Sys
 :
  sig
    value command_ok
     : string -> res unit exn
    ;
  end
;
