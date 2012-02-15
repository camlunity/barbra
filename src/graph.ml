(** Minimal unweighted directed graphs implementation. *)

open StdLabels

module type OrderedType = sig
  type t
  val compare : t -> t -> int
end


module Make(Ord : OrderedType) = struct
  type graph = (vertex, vertex list) Hashtbl.t

  and vertex = Ord.t
  and edge   = (vertex * vertex)

  exception Cycle_found of vertex list

  type color =
    | White  (* To be processed. *)
    | Gray   (* In processing. *)
    | Black  (* Seen. *)

  let rec make ~f nodes =
    let size = List.length nodes in
    let g    = Hashtbl.create size in begin
      List.iter nodes ~f:(fun node ->
        let (v, adjacent) = f node in
        Hashtbl.replace g v adjacent;

        (* Make sure we don't have any 'hanging' vertices. *)
        List.iter adjacent ~f:(fun v ->
          if not (Hashtbl.mem g v) then
            Hashtbl.add g v []
        )
      );

      g
    end

  and vertices g =
    Hashtbl.fold (fun v _ acc -> v :: acc) g []

  and edges g =
    Hashtbl.fold (fun v1 adjacent acc ->
      List.fold_right adjacent
        ~init:acc
        ~f:(fun v2 acc -> (v1, v2) :: acc)
    ) g []

  and topsort g =
    let (_, post) = dfs g (vertices g) in post

  (* Internal. *)

  and resolve_cycle v1 v2 parents =
    let rec inner v1 v2 acc =
      if v1 = v2 then
        v2 :: acc
      else
        let parent = Hashtbl.find parents v1 in
        inner parent v2 (v1 :: acc)
    in inner v1 v2 []

  and dfs g vs =
    let size = Hashtbl.length g in
    let pre  = ref [] in  (* preorder *)
    let post = ref [] in  (* postorder *)
    let seen = Hashtbl.create size in
    let parents = Hashtbl.create size in

    let rec visit v1 =
      Hashtbl.replace seen v1 Gray;
      pre := v1 :: !pre;

      List.iter ~f:(fun v2 ->
        match Hashtbl.find seen v2 with
          | White -> Hashtbl.add parents v2 v1; visit v2
          | Gray  ->
            raise (Cycle_found (resolve_cycle v1 v2 parents))
          | Black -> ()
      ) (Hashtbl.find g v1);

      Hashtbl.replace seen v1 Black;
      post := v1 :: !post
    in begin
      Hashtbl.iter (fun v _ -> Hashtbl.add seen v White) g;
      List.iter ~f:visit vs;
      (!pre, !post)
    end
end
