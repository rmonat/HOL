structure type_pp :> type_pp =
struct

open Feedback Type Portable HOLgrammars type_grammar

datatype mygrav
   = Sfx of int
   | Lfx of int * string
   | Rfx of int * string
   | Top

datatype single_rule
   = SR
   | IR of associativity * string

val ERR = mk_HOL_ERR "type_pp" "pp_type";

val pp_num_types = ref true
val _ = register_btrace("pp_num_types", pp_num_types)

fun dest_numtype ty = let
  open Arbnum
  val _ = (* respect pp_num_types flag *)
      !pp_num_types orelse raise mk_HOL_ERR "" "" ""
  val _ = (* exception: don't print :one as one *)
      let val {Thy,Tyop,Args} = dest_thy_type ty
      in
        if Thy = "one" andalso Tyop = "one" then raise mk_HOL_ERR "" "" ""
        else ()
      end
  fun recurse (base, acc) ty = let
    val {Thy,Tyop,Args} = dest_thy_type ty
  in
    case (Thy,Tyop) of
      ("one", "one") => acc + base
    | ("fcp", "bit1") => recurse (two * base, acc + base) (hd Args)
    | ("fcp", "bit0") => recurse (two * base, acc) (hd Args)
    | _ => raise mk_HOL_ERR "" "" ""
  end
in
  toString (recurse (one, zero) ty)
end

val pp_array_types = ref true
val _ = register_btrace ("pp_array_types", pp_array_types)

fun dest_arraytype ty = let
  val {Thy, Tyop, Args} = dest_thy_type ty
in
  if Thy = "fcp" andalso Tyop = "cart" then (hd Args, hd (tl Args))
  else raise ERR "dest_arraytype: not an array type"
end

val show_kinds = ref false
val _ = Feedback.register_btrace("kinds", show_kinds)

fun pp_type0 (G:grammar) = let
  fun lookup_tyop s = let
    fun recurse [] = NONE
      | recurse (x::xs) = let
        in
          case x of
            (p, SUFFIX slist) =>
              if Lib.mem s slist then SOME (p, SR) else recurse xs
          | (p, INFIX (slist, a)) => let
              val res = List.find (fn r => #opname r = s) slist
            in
              case res of
                NONE => recurse xs
              | SOME r => SOME(p, IR(a,#parse_string r))
            end
          | (p, ARRAY_SFX) => recurse xs
        end
  in
    recurse (rules G) : (int * single_rule) option
  end

  fun pr_ty pps ty grav depth = let
    val {add_string, add_break, begin_block, end_block,...} =
      with_ppstream pps
    fun pbegin b = if b then add_string "(" else ()
    fun pend b = if b then add_string ")" else ()

    fun print_args grav0 args = let
      val parens_needed = case args of [_] => false | _ => true
      val grav = if parens_needed then Top else grav0
    in
      pbegin parens_needed;
      begin_block INCONSISTENT 0;
      pr_list (fn arg => pr_ty pps arg grav (depth - 1))
              (fn () => add_string ",") (fn () => add_break (1, 0)) args;
      end_block();
      pend parens_needed
    end

    fun print_var grav (s,k,r) =
        if (k <> Kind.typ orelse r <> 0) andalso !show_kinds then let
            val parens_needed =
                 case grav of Top => false | _ => true
          in
            pbegin parens_needed;
            add_string s;
            if k <> Kind.typ then let
                val p = r <> 0 andalso not (Kind.is_arity k)
              in
                add_string "::";
                pbegin p;
                Kind.pp_kind pps k;
                pend p
              end
            else ();
            if r <> 0 then (add_string " <= ";
                            add_string (Int.toString r))
            else ();
            pend parens_needed
          end
        else add_string s

  in
    if depth = 0 then add_string "..."
    else
      if is_vartype ty then print_var grav (dest_vartype_opr ty)
      else let
          val s = dest_numtype ty
        in
          add_string s
        end handle HOL_ERR _ =>
        let
          val _ = !pp_array_types orelse
                  raise mk_HOL_ERR "" "" "" (* will be caught below *)
          val (bty, cty) = dest_arraytype ty
          (* ignore parenthesis requirements on sub-arguments on assumption that
             all suffixes, including array bracketting, are tightest binders in grammar
             and all at the same tightest level. *)
        in
          pr_ty pps bty grav (depth - 1);
          add_string "[";
          pr_ty pps cty Top (depth - 1);
          add_string "]"
        end handle HOL_ERR _ =>
        if Lib.can dest_type ty then let
            val (Tyop, Args) = type_grammar.abb_dest_type G ty
            fun print_ghastly () = let
              val {Thy,Tyop,...} = dest_thy_type ty
            in
              add_string "(";
              begin_block INCONSISTENT 0;
              if not (null Args) then (print_args Top Args; add_break(1,0))
              else ();
              add_string (Thy ^ "$" ^ Tyop);
              end_block();
              add_string ")"
            end
          in
            case Args of
              [] => let
              in
                case lookup_tyop Tyop of
                  NONE => print_ghastly ()
                | _ => add_string Tyop
              end
            | [arg1, arg2] =>
              (let
                 val (prec, rule) = valOf (lookup_tyop Tyop)
               in
                 case rule of
                   SR => let
                     val addparens =
                         case grav of
                           Rfx(n, _) => (n > prec)
                         | _ => false
                   in
                     pbegin addparens;
                     begin_block INCONSISTENT 0;
                     (* knowing that there are two args, we know that they will
                        be printed with parentheses, so the gravity we pass in
                        here makes no difference. *)
                     print_args Top Args;
                     add_break(1,0);
                     add_string Tyop;
                     end_block();
                     pend addparens
                   end
                 | IR(assoc, printthis) => let
                     val parens_needed =
                         case grav of
                           Sfx n => (n > prec)
                         | Lfx (n, s) => if s = printthis then assoc <> LEFT
                                         else (n >= prec)
                         | Rfx (n, s) => if s = printthis then assoc <> RIGHT
                                         else (n >= prec)
                         | _ => false
                   in
                     pbegin parens_needed;
                     begin_block INCONSISTENT 0;
                     pr_ty pps arg1 (Lfx (prec, printthis)) (depth - 1);
                     add_break(1,0);
                     add_string printthis;
                     add_break(1,0);
                     pr_ty pps arg2 (Rfx (prec, printthis)) (depth -1);
                     end_block();
                     pend parens_needed
                   end
               end handle Option => print_ghastly())
            | _ => let
                val (prec, _) = valOf (lookup_tyop Tyop)
                val addparens =
                    case grav of
                      Rfx (n, _) => (n > prec)
                    | _ => false
              in
                pbegin addparens;
                begin_block INCONSISTENT 0;
                print_args (Sfx prec) Args;
                add_break(1,0);
                add_string Tyop;
                end_block();
                pend addparens
              end handle Option => print_ghastly()
          end
        else let
            (* not a normal "classic" type operator with arguments *)
            open TypeView
          in
            case fromType ty of
              TyV_App _ => let
                val (base, args) = strip_app_type ty
              in
                begin_block INCONSISTENT 0;
                print_args (Sfx 200) args;
                add_break(1,0);
                pr_ty pps base (Sfx 200) (depth - 1);
                end_block ()
              end
            | TyV_Abs _ => let
                val (vars, body) = strip_abs_type ty
                val parens = case grav of
                               Lfx _ => true
                             | _ => false
              in
                pbegin parens;
                begin_block INCONSISTENT 0;
                add_string "\\";
                pr_list (fn arg => pr_ty pps arg grav (depth - 1))
                        (fn () => ())
                        (fn () => add_break (1, 0))
                        vars;
                add_string ".";
                add_break (1,0);
                pr_ty pps body Top (depth - 1);
                end_block ();
                pend parens
              end
            | TyV_All _ => let
                val (vars, body) = strip_univ_type ty
                val parens = case grav of
                               Lfx _ => true
                             | _ => false
              in
                pbegin parens;
                begin_block INCONSISTENT 0;
                add_string "!";
                pr_list (fn arg => pr_ty pps arg grav (depth - 1))
                        (fn () => ())
                        (fn () => add_break (1, 0))
                        vars;
                add_string ".";
                add_break (1,0);
                pr_ty pps body Top (depth - 1);
                end_block ();
                pend parens
              end
            | _ => raise Fail "type_pp: this can't happen"
          end
  end
in
  pr_ty
end

fun pp_type G = let
  val baseprinter = pp_type0 G
in
  (fn pps => fn ty => baseprinter pps ty Top (!Globals.max_print_depth))
end

fun pp_type_with_depth G = let
  val baseprinter = pp_type0 G
in
  (fn pps => fn depth => fn ty => baseprinter pps ty Top depth)
end

end; (* struct *)

(* testing

val G = parse_type.BaseHOLgrammar;
fun p ty =
  Portable.pp_to_string 75
   (fn pp => fn ty => type_pp.pp_type G pp ty type_pp.Top 100) ty;

new_type {Name = "fmap", Arity = 2};

val G' = [(0, parse_type.INFIX("->", "fun", parse_type.RIGHT)),
     (1, parse_type.INFIX("=>", "fmap", parse_type.NONASSOC)),
     (2, parse_type.INFIX("+", "sum", parse_type.LEFT)),
     (3, parse_type.INFIX("#", "prod", parse_type.RIGHT)),
     (100, parse_type.SUFFIX("list", true)),
     (101, parse_type.SUFFIX("fun", false)),
     (102, parse_type.SUFFIX("prod", false)),
     (103, parse_type.SUFFIX("sum", false))];
fun p ty =
  Portable.pp_to_string 75
   (fn pp => fn ty => type_pp.pp_type G' pp ty type_pp.Top 100) ty;

p (Type`:(bool,num)fmap`)

*)
