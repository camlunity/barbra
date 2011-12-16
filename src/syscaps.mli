val first : (Types.cap * 'a) list -> ('a, unit) Types.res


(* exported for old code *)

(** [ensure cmd] Returns [true] if a given [command] is available
    on the host system and [false] otherwise. *)
val ensure : string -> bool
