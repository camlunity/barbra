val first : (Types.cap * 'a) list -> ('a, unit) Types.res


(* exported for old code *)

(** [ensure cmd opt] Returns [true] if a given [cmd] is available
    on the host system and [false] otherwise.  It is checked by
    executing "[cmd] [opt]" process. *)
val ensure : string -> string -> bool
