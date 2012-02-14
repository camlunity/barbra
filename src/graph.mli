(** Minimal unweighted directed graphs implementation. *)

module type OrderedType = Set.OrderedType

module Make (Ord : OrderedType) : sig
  type key   = Ord.t
  type graph = (key, key list) Hashtbl.t

  val make : f:('node -> (key * key list)) -> 'node list -> graph
  (** [make ~f nodes] created a graph from a key function [f] and
      a list of [nodes]. *)

  val dfs  : f:(key -> unit) -> graph -> (key list * key list)
  (** [dfs ~f graph] performs a depth-first search on the graph,
      applying [f] to each vertes. Returns a pair, where the first
      element is a list of graph vertices in the pre-order, and second
      is a list of vertices in the post-order. *)

  val topsort : graph -> key list
  (** [topsort graph] return a topological ordering of the graph. *)
end
