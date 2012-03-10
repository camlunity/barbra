open Types

type t =
    {
      world : Recipe.world;
      deps  : dep list
    }

val from_string : string -> t
val from_file   : string -> t

val resolve : t -> t
