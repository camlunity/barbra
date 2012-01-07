open Types

type ast_meta = [ `Make of string
                | `Flag of string
                | `Patch of string
                ]
type ast_dep  = (string * package * ast_meta list)
type ast_version = string
