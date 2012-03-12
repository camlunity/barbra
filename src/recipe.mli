open Types

exception Recipe_not_found of (string * string)
exception Recipe_invalid of string

class repository : name:string -> path:string -> object
  method resolve : recipe:string -> dep
  (** [resolve ~recipe] Resolves a given [recipe] within the current
      repository.

      Raises [Recipe_not_found recipe path] when requested recipe is
      not present in this repository.
      Raises [Recipe_invalid recipe] when requested recipe has invalid
      syntax (for example is missing 'Dep ...' section) *)

  method iter : f:(string -> unit) -> unit
  (** [iter ~f] Traverses all known recipes in the current repository
      and applies [f] to each of them. *)
end

class world : repositories:(string * string) list -> object
  method resolve : repository:string -> recipe:string -> dep
  (** [resolve ~repository ~recipe] Resolves a [recipe] in a repository
      with a given [name]. *)

  method resolve_any : recipe:string -> dep
  (** [resolve_any ~recipe] Tries to resolve a [recipe] in all known
      repositories and return the first match found. *)

  method iter : f:(string -> string -> unit) -> unit
  (** [iter ~f] Traverses all recipes in all known repositories and
      applies [f] to each of them. *)
end
