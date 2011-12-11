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

    value bindres : withres 'a 'r -> 'a -> ('r -> M.m 'z) -> M.m 'z
    ;

    value with_alt :
      withres 'a 'r ->
      withres 'b 'r ->
      withres ('a * 'b) (option exn * 'r)
    ;

    value with_identity : withres 'r 'r;

    value premap
      : ('a -> 'b) -> withres 'b 'r -> withres 'a 'r
    ;

    type dir_abstract
    ;

    value with_sys_chdir : withres string dir_abstract
    ;

  end
 =
  struct

    type withres 'a 'r =
      { cons : 'a -> M.m 'r
      ; fin : 'r -> M.m unit
      }
    ;

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

    value bindres wr a f =
      wr.cons a >>= fun r ->
      M.catch
        (fun () ->
           f r >>= fun z ->
           wr.fin r >>= fun () ->
           M.return z
        )
        (fun e ->
           wr.fin r >>= fun () ->
           M.error e
        )
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
