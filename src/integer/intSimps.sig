signature intSimps =
sig

  val int_compset : unit -> computeLib.compset

  val INT_REDUCE_ss : simpLib.ssdata

  val int_ss : simpLib.simpset

  val INT_MUL_AC_ss : simpLib.ssdata
  val INT_ADD_AC_ss : simpLib.ssdata

  val REDUCE_CONV : Term.term -> Thm.thm
  val RED_CONV : Term.term -> Thm.thm

  val collect_additive_consts : Term.term -> Thm.thm
  (* collects all integer literals in an additive term and sums them;
     e.g.:  3 + x + ~1  --> x + 2
     the collected numeral always appears on the right,
     fails if there is no collecting to be done *)

end;
