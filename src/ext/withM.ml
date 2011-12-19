module type MonadError
 =
  sig
    type m +'a;
    value return : 'a -> m 'a;
    value bind : ('a -> m 'b) -> m 'a -> m 'b;
    value bind_rev : m 'a -> ('a -> m 'b) -> m 'b;
    value error : exn -> m 'a;
    value catch : (unit -> m 'a) -> (exn -> m 'a) -> m 'a;
  end
;


module Identity
 =
  struct
    type m +'a = 'a;
    external return : 'a -> m 'a = "%identity";
    value bind f m = f m;
    value bind_rev m f = f m;
    value error = raise;
    value catch func handler = try func () with [e -> handler e];
  end
;


(*
module LwtIO
 =
  struct
    type m +'a = Lwt.t 'a;
    value return = Lwt.return;
    value bind = Lwt.( =<< );
    value bind_rev = Lwt.( >>= );
    value error = Lwt.fail;
    value catch = Lwt.catch;
  end
;
*)


(*
module TestIdentity = (Identity : MonadError);
module TestLwtIO = (LwtIO : MonadError);
*)


module W (M : MonadError)
 :
  sig 

    type withres 'a 'r =
      { cons : 'a -> M.m 'r
      ; fin : 'r -> M.m unit
      }
    ;

    type wrfun 'a 'r 'z = 'a -> ('r -> M.m 'z) -> M.m 'z
    ;

    value bindres : withres 'a 'r -> wrfun 'a 'r 'z
    ;

    value with_alt :
      withres 'a 'r ->
      withres 'b 'r ->
      withres ('a * 'b) (option exn * 'r)
    ;

    value wr_alt :
      withres 'a 'r ->
      withres 'b 'r ->
      wrfun ('a * 'b) ('r * option exn) 'z
    ;

    value with_identity : withres 'r 'r;

    value premap
      : ('a -> 'b) -> withres 'b 'r -> withres 'a 'r
    ;

    type dir_abstract
    ;

    value with_sys_chdir : withres string dir_abstract
    ;

    value sequence : withres 'a 'r -> wrfun (list 'a) (list 'r) 'z
    ;

  end
 =
  struct

    type withres 'a 'r =
      { cons : 'a -> M.m 'r
      ; fin : 'r -> M.m unit
      }
    ;

    type wrfun 'a 'r 'z = 'a -> ('r -> M.m 'z) -> M.m 'z
    ;

(*
    сделать что-то наподобие передачи fin_all : unit -> M.m unit,
    которую в простом случае (bindres) создавать на основании
    созданного ресурса: fun () -> wr.fin res, а в случаях sequence --
    списком из кусков.
    заодно with_alt из треша с мутабельным превратится во что-то
    более красивое, но на внутренних структурах типа fin_all.
*)

    type finitem = unit -> M.m unit;
    type finlist = list finitem;

    value ( %> ) f g = fun x -> g (f x)
    ;

    value premap
      : ('a -> 'b) -> withres 'b 'r -> withres 'a 'r
      = fun ab wbr ->
          { cons = ab %> wbr.cons
          ; fin = wbr.fin
          }
    ;

    value with_identity =
      { cons = M.return
      ; fin = fun _r -> M.return ()
      }
    ;

    value ( >>= ) = M.bind_rev;

    value rec close_fl
     : finlist -> M.m unit
     = fun [ [] -> M.return () | [h :: t] -> h () >>= fun () -> close_fl t ]
    ;

    value run_fl
     : finlist -> ('a -> M.m 'z) -> 'a -> M.m 'z
     = fun fl f a ->
         M.catch
           (fun () -> f a >>= fun z -> close_fl fl >>= fun () -> M.return z)
           (fun e -> close_fl fl >>= fun () -> M.error e)
    ;

    value f_of_wr
     : withres 'a 'r -> 'r -> finitem
     = fun wr r ->
      fun () -> wr.fin r
    ;

    value bindres wr a f =
      wr.cons a >>= fun r ->
      run_fl [f_of_wr wr r] f r
    ;

    value with_alt wr1 wr2 =
      let fin = ref wr1.fin in
      { cons = fun (a, b) ->
          M.catch
            (fun () ->
               wr1.cons a >>= fun r ->
               M.return (None, r)
            )
            (fun e ->
               wr2.cons b >>= fun r ->
               ( fin.val := wr2.fin
               ; M.return (Some e, r)
               )
            )
      ; fin = fun (_opt_err, r) -> fin.val r
      }
    ;

    value wr_alt
     : withres 'a 'r -> withres 'b 'r -> wrfun ('a * 'b) ('r * option exn) 'z
     = fun wr1 wr2 ->
         fun (a, b) f ->
           M.catch
             (fun () ->
                wr1.cons a >>= fun r1 ->
                M.return ((r1, None), [f_of_wr wr1 r1])
             )
             (fun e ->
                wr2.cons b >>= fun r2 ->
                M.return ((r2, Some e), [f_of_wr wr2 r2])
             )
           >>= fun (r_and_opterr, fl) ->
           run_fl fl f r_and_opterr
    ;

    type dir_abstract = string
    ;

    value with_sys_chdir
     : withres string dir_abstract
     =
       { cons = fun new_dir ->
           M.catch 
             (fun () ->
                let old_dir = Sys.getcwd () in
                let () = Sys.chdir new_dir in
                M.return old_dir
             )
             M.error
       ; fin = fun old_dir ->
           M.catch
             (fun () -> M.return (Sys.chdir old_dir))
             M.error
       }
    ;


    value sequence
     : withres 'a 'r -> wrfun (list 'a) (list 'r) 'z
     = fun wr ->
         fun lst_a f ->
           (cons_all lst_a
            where rec cons_all ?(lst_r_rev=[]) ?(lst_fin_rev=[]) lst_a =
              match lst_a with
              [ [] -> M.return (List.rev lst_r_rev, lst_fin_rev)
              | [h :: t] ->
                  M.catch
                    (fun () ->
                       wr.cons h >>= fun r ->
                       cons_all
                         ~lst_r_rev:[r :: lst_r_rev]
                         ~lst_fin_rev:[f_of_wr wr r :: lst_fin_rev]
                         t
                    )
                    (fun e ->
                       close_fl lst_fin_rev >>= fun () ->
                       M.error e
                    )
              ]
           )
           >>= fun (lst_r, lst_fin_rev) ->
           run_fl lst_fin_rev f lst_r
    ;


  end
;


module WithI = W(Identity)
;

(*
module WithLwtIO = W(LwtIO)
;
*)

module WithRes = W(Res)
;
