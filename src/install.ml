open Types



let install
 : source -> (unit, exn) res
 = fun source ->

     ignore (source#fetch ~dest_source_dir:"asd"); raise Exit
