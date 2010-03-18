(* Copyright (c) 2010 Tjark Weber. All rights reserved. *)

(* Entry point into HolQbfLib. 'disprove' can disprove QBFs in prenex form by
   validating a certificate of invalidity generated by the QBF solver Squolem.
*)

structure HolQbfLib :> HolQbfLib = struct

  (* returns a theorem "t |- F" *)
  fun disprove t =
  let
    val path = FileSys.tmpName ()
    val _ = QDimacs.write_qdimacs_file path t
    (* the actual system call to Squolem *)
    val cmd = "squolem --save-certificate " ^ path ^ " >& /dev/null"
    val _ = if !QbfTrace.trace > 1 then
        Feedback.HOL_MESG ("HolQbfLib: calling external command '" ^ cmd ^ "'")
      else ()
    val _ = Systeml.system_ps cmd
    val cert_path = path ^ ".qbc"  (* the file name is hard-wired in Squolem *)
    val cert = QbfCertificate.read_certificate_file cert_path
    (* delete temporary files *)
    val _ = if !QbfTrace.trace < 4 then
        List.app (fn path => OS.FileSys.remove path handle SysErr _ => ())
          [path, cert_path]
      else ()
  in
    QbfCertificate.check t cert
  end

end