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
end

class world : repositories:(string * string) list -> object
  method resolve : repository:string -> recipe:string -> dep
  (** [resolve ~repository ~recipe] Resolves a [recipe] in a repository
      with a given [name]. *)
end
