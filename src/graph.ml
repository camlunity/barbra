(** Minimal unweighted directed graphs implementation. *)

(* Use Hashtbl to store key colors; raise Cycle_found in dfs *)

open StdLabels

type 'key graph = ('key, 'key list) Hashtbl.t

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
  let seen = Hashtbl.create (Hashtbl.length g) in
  let rec visit key =
    let adjacent = Hashtbl.find g key in

      incr time;
      pre := key :: !pre;

      if not (Hashtbl.mem seen key) then begin
        f key;
        List.iter ~f:visit adjacent;

        incr time;
        Hashtbl.add seen key true;
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
