(** Minimal unweighted directed graphs implementation. *)

module type OrderedType = sig
  type t
  val compare : t -> t -> int
end


module Make(Ord : OrderedType) : sig
  type graph

  type vertex = Ord.t
  type edge   = (vertex * vertex)

  exception Cycle_found of vertex list

  val make : f:('node -> (vertex * vertex list)) -> 'node list -> graph
  (** [make ~f nodes] created a graph from a vertex function [f] and
      a list of [nodes]. *)

  val transpose : graph -> graph

  val vertices : graph -> vertex list
  val edges    : graph -> edge list

  val topsort  : graph -> vertex list
  (** [topsort graph] return a topological ordering of the graph. *)
end
