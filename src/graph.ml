(** Minimal unweighted directed graphs implementation. *)

module type OrderedType = Set.OrderedType

module Make (Ord : OrderedType) = struct
  open StdLabels

  module Set = Set.Make(Ord)

  type key   = Ord.t
  type graph = (key, key list) Hashtbl.t

  let rec make ~f nodes =
    let size = List.length nodes in
    let g    = Hashtbl.create size in begin
      List.iter nodes ~f:(fun node ->
        let (key, adjacent) = f node in
        Hashtbl.add g key adjacent
      );

      g
    end

  and dfs ~f g =
    let time = ref 0 in
    let pre  = ref [] in  (* preorder *)
    let post = ref [] in  (* postorder *)
    let seen = ref Set.empty in
    let rec visit key =
      let adjacent = Hashtbl.find g key in

      incr time;
      pre := key :: !pre;

      if not (Set.mem key !seen) then begin
        f key;
        List.iter ~f:visit adjacent;

        incr time;
        seen := Set.add key !seen;
        post := key :: !post
      end
    in begin
      Hashtbl.iter (fun key adjacent ->
        visit key;
        List.iter ~f:visit adjacent
      ) g;

      (!pre, !post)
    end

  and topsort g =
    let (_, post) = dfs ~f:ignore g in List.rev post
end
