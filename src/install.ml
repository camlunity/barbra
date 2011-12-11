open Types



let install
 : source -> (unit, exn) res
 = fun source ->

     ignore source; raise Exit
