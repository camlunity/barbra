open Types



let install
 : install
 = object

     method install ~path =

       let open WithM in
       let open Res in

       WithRes.bindres WithRes.with_sys_chdir path
         (fun _old_path ->

            return ()

         )

   end
