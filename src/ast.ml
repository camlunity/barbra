open Types

type meta = [ `Make of string
            | `Flag of string
            | `Patch of string
            ]
type dep = (string * package * meta list)
type inc = string
type version = string  