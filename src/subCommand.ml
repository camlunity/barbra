open Common

type t = { name  : string
         ; synopsis : string
         ; help  : string
         ; usage : string
         ; specs : (Arg.key * Arg.spec * Arg.doc) list
         ; anon  : string -> unit
         ; main  : unit -> unit
         }

module StringMap = Map.Make(String)

let all = ref StringMap.empty

let make ~name ~synopsis ?(help="") ?(usage="") main =
  { name; synopsis; help; usage
  ; specs = []
  ; anon = (Log.error "Don't know what to do with %S")
  ; main
  }

and register ({ name; _ } as t) =
  all := StringMap.add name t !all

and find name =
  try
    StringMap.find name !all
  with Not_found ->
    failwithf "Subcommand %S doesn't exist" name

and fold ~f ~init =
  StringMap.fold f !all init
