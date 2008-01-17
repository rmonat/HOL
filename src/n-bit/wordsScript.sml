(* ========================================================================= *)
(* FILE          : wordsScript.sml                                           *)
(* DESCRIPTION   : A model of binary words. Based on John Harrison's         *)
(*                 treatment of finite Cartesian products (TPHOLs 2005)      *)
(* AUTHOR        : (c) Anthony Fox, University of Cambridge                  *)
(* DATE          : 2005                                                      *)
(* ========================================================================= *)

(* interactive use:
  app load ["pred_setTheory", "bitTheory", "numeral_bitTheory",
            "sum_numTheory", "fcpLib"];
*)

open HolKernel Parse boolLib bossLib;
open Q arithmeticTheory pred_setTheory;
open bitTheory sum_numTheory fcpTheory;

val _ = new_theory "words";

(* ------------------------------------------------------------------------- *)

infix \\ << >>

val op \\ = op THEN;
val op << = op THENL;
val op >> = op THEN1;

val Abbr = BasicProvers.Abbr;
val export_rewrites = BasicProvers.export_rewrites
val fcp_ss = std_ss ++ fcpLib.FCP_ss;
val ai = computeLib.auto_import_definitions;

val WL = ``dimindex (:'a)``;
val HB = ``^WL - 1``;

val _ = ai := false;

val dimword_def  = Define `dimword (:'a) = 2 ** ^WL`
val INT_MIN_def  = Define `INT_MIN (:'a) = 2 ** ^HB`

val _ = ai := true;

val UINT_MAX_def = Define `UINT_MAX (:'a) = dimword(:'a) - 1`;
val INT_MAX_def  = Define `INT_MAX (:'a) = INT_MIN(:'a) - 1`;

val dimword_ML = rhs (#2 (strip_forall (concl dimword_def)))
val INT_MIN_ML = rhs (#2 (strip_forall (concl INT_MIN_def)))

val _ = type_abbrev("word", ``:bool['a]``);

(* ------------------------------------------------------------------------- *)
(*  Domain transforming maps : definitions                                   *)
(* ------------------------------------------------------------------------- *)

val _ = ai := false;

val w2n_def = Define`
  w2n (w:'a word) = SUM ^WL (\i. SBIT (w ' i) i)`;

val n2w_def = Define`
  (n2w:num->('a word)) n = FCP i. BIT i n`;

val w2w_def = Define`
  (w2w:'a word -> 'b word) w = n2w (w2n w)`;

val sw2sw_def = Define`
  (sw2sw:'a word -> 'b word) w =
    n2w (SIGN_EXTEND (dimindex(:'a)) (dimindex(:'b)) (w2n w))`;

val _ = add_bare_numeral_form (#"w", SOME "n2w");

(* ------------------------------------------------------------------------- *)
(*  The Boolean operations : definitions                                     *)
(* ------------------------------------------------------------------------- *)

val _ = ai := true;

val word_T_def = Define`
  word_T = n2w:num->('a word) (UINT_MAX(:'a))`;

val word_L_def = Define`
  word_L = n2w:num->('a word) (INT_MIN(:'a))`;

val word_H_def = Define`
  word_H = n2w:num->('a word) (INT_MAX(:'a))`;

val _ = ai := false;

val word_1comp_def = Define`
  word_1comp (w:'a word) = (FCP i. ~(w ' i)):'a word`;

val word_and_def = Define`
  word_and (v:'a word) (w:'a word) =
    (FCP i. (v ' i) /\ (w ' i)):'a word`;

val word_or_def = Define`
  word_or (v:'a word) (w:'a word) =
    (FCP i. (v ' i) \/ (w ' i)):'a word`;

val word_xor_def = Define`
  word_xor (v:'a word) (w:'a word) =
    (FCP i. ~((v ' i) = (w ' i))):'a word`;

val _ = overload_on ("~", Term`$word_1comp`);
val _ = overload_on ("~", Term`bool$~`);
val _ = overload_on ("&&",Term`$word_and`);
val _ = overload_on ("!!",Term`$word_or`);
val _ = overload_on ("??",Term`$word_xor`);
val _ = overload_on ("Tw",Term`word_T`);
val _ = overload_on ("UINT_MAXw",Term`word_T`);
val _ = overload_on ("INT_MAXw",Term`word_H`);
val _ = overload_on ("INT_MINw",Term`word_L`);

val _ = add_infix("&&",400,HOLgrammars.RIGHT);
val _ = add_infix("!!",300,HOLgrammars.RIGHT);
val _ = add_infix("??",300,HOLgrammars.RIGHT);

(* ------------------------------------------------------------------------- *)
(*  Bit field operations : definitions                                       *)
(* ------------------------------------------------------------------------- *)

val word_lsb_def = Define`
  word_lsb (w:'a word) = w ' 0`;

val word_msb_def = Define`
  word_msb (w:'a word) = w ' ^HB`;

val word_slice_def = Define`
  word_slice h l = \w:'a word.
    (FCP i. l <= i /\ i <= MIN h ^HB /\ w ' i):'a word`;

val word_bits_def = Define`
  word_bits h l = \w:'a word.
    (FCP i. i + l <= MIN h ^HB /\ w ' (i + l)):'a word`;

val word_extract_def = Define`
  word_extract h l = w2w o word_bits h l`;

val word_bit_def = Define`
  word_bit b (w:'a word) = b <= ^HB /\ w ' b`;

val word_reverse_def = Define`
  word_reverse (w:'a word) = (FCP i. w ' (^HB - i)):'a word`;

val word_modify_def = Define`
  word_modify f (w:'a word) = (FCP i. f i (w ' i)):'a word`;

val BIT_SET_def = Define`
  BIT_SET i n =
    if n = 0 then
      {}
    else
      if ODD n then
        i INSERT (BIT_SET (SUC i) (n DIV 2))
      else
        BIT_SET (SUC i) (n DIV 2)`;

val _ = ai := true;

val word_len_def = Define`
  word_len (w:'a word) = dimindex (:'a)`;

val _ = ai := false;

val _ = overload_on ("<>",Term`$word_slice`);
val _ = overload_on ("--",Term`$word_bits`);
val _ = overload_on ("><",Term`$word_extract`);

val _ = add_infix("<>",350,HOLgrammars.RIGHT);
val _ = add_infix("--",350,HOLgrammars.RIGHT);
val _ = add_infix("><",350,HOLgrammars.RIGHT);

(* ------------------------------------------------------------------------- *)
(*  Word arithmetic: definitions                                             *)
(* ------------------------------------------------------------------------- *)

val word_2comp_def = Define`
  word_2comp (w:'a word) =
    n2w:num->('a word) (dimword(:'a) - w2n w)`;

val word_add_def = Define`
  word_add (v:'a word) (w:'a word) =
    n2w:num->('a word) (w2n v + w2n w)`;

val word_mul_def = Define`
  word_mul (v:'a word) (w:'a word) =
    n2w:num->('a word) (w2n v * w2n w)`;

val word_log2_def = Define`
  word_log2 (w:'a word) = (n2w (LOG2 (w2n w)):'a word)`;

val _ = ai := true;

val word_sub_def = Define`
  word_sub (v:'a word) (w:'a word) = word_add v (word_2comp w)`;

val word_div_def = Define`
  word_div (v: 'a word) (w: 'a word) =
    n2w:num->('a word) (w2n v DIV w2n w)`;

val word_sdiv_def = Define`
  word_sdiv a b =
    if word_msb a then
      if word_msb b then
        word_div (word_2comp a) (word_2comp b)
      else
        word_2comp (word_div (word_2comp a) b)
    else
      if word_msb b then
        word_2comp (word_div a (word_2comp b))
      else
        word_div a b`;

val word_L2_def = Define `word_L2 = word_mul word_L word_L`;

val _ = ai := false;

val _ = overload_on ("+", Term`$word_add`);
val _ = overload_on ("-", Term`$word_sub`);
val _ = overload_on ("-", Term`$word_2comp`);
val _ = overload_on ("*", Term`$word_mul`);
val _ = overload_on ("//",Term`$word_div`);
val _ = overload_on ("/", Term`$word_sdiv`);

val _ = set_fixity "//" (Infixl 600);
val _ = set_fixity "/"  (Infixl 600);

val _ = overload_on ("INT_MINw2",Term`word_L2`);

(* ------------------------------------------------------------------------- *)
(*  Shifts : definitions                                                     *)
(* ------------------------------------------------------------------------- *)

val word_lsl_def = Define`
  word_lsl (w:'a word) n =
    (FCP i. i < ^WL /\ n <= i /\ w ' (i - n)):'a word`;

val word_lsr_def = Define`
  word_lsr (w:'a word) n =
    (FCP i. i + n < ^WL /\ w ' (i + n)):'a word`;

val word_asr_def = Define`
  word_asr (w:'a word) n =
    (FCP i. if ^WL <= i + n then
              word_msb w
            else
              w ' (i + n)):'a word`;

val word_ror_def = Define`
  word_ror (w:'a word) n =
    (FCP i. w ' ((i + n) MOD ^WL)):'a word`;

val word_rol_def = Define`
  word_rol (w:'a word) n =
    word_ror w (^WL - n MOD ^WL)`;

val word_rrx_def = Define`
  word_rrx(c, w:'a word) =
    (word_lsb w,
     (FCP i. if i = ^HB then c else (word_lsr w 1) ' i):'a word)`;

val _ = overload_on ("<<", Term`$word_lsl`);
val _ = overload_on (">>", Term`$word_asr`);
val _ = overload_on (">>>",Term`$word_lsr`);
val _ = overload_on ("#>>",Term`$word_ror`);
val _ = overload_on ("#<<",Term`$word_rol`);

val _ = add_infix("<<", 680,HOLgrammars.LEFT);
val _ = add_infix(">>", 680,HOLgrammars.LEFT);
val _ = add_infix(">>>",680,HOLgrammars.LEFT);
val _ = add_infix("#>>",680,HOLgrammars.LEFT);
val _ = add_infix("#<<",680,HOLgrammars.LEFT);

(* ------------------------------------------------------------------------- *)
(*  Concatenation : definition                                               *)
(* ------------------------------------------------------------------------- *)

val _ = ai := true;

val word_join_def = Define`
  (word_join (v:'a word) (w:'b word)):('a + 'b) word =
    let cv = (w2w v):('a + 'b) word
    and cw = (w2w w):('a + 'b) word
    in  (cv << (dimindex (:'b))) !! cw`;

val word_concat_def = Define`
  word_concat (v:'a word) (w:'b word) = w2w (word_join v w)`;

val _ = overload_on ("@@",Term`$word_concat`);

val _ = add_infix("@@",700,HOLgrammars.RIGHT);

(* ------------------------------------------------------------------------- *)
(*  Orderings : definitions                                                  *)
(* ------------------------------------------------------------------------- *)

val nzcv_def = Define `
  nzcv (a:'a word) (b:'a word) =
    let q = w2n a + w2n ($- b) in
    let r = (n2w q):'a word in
      (word_msb r,r = 0w,BIT ^WL q \/ (b = 0w),
     ~(word_msb a = word_msb b) /\ ~(word_msb r = word_msb a))`;

val _ = ai := false;

val word_lt_def = Define`
  word_lt a b = let (n,z,c,v) = nzcv a b in ~(n = v)`;

val word_gt_def = Define`
  word_gt a b = let (n,z,c,v) = nzcv a b in ~z /\ (n = v)`;

val word_le_def = Define`
  word_le a b = let (n,z,c,v) = nzcv a b in z \/ ~(n = v)`;

val word_ge_def = Define`
  word_ge a b = let (n,z,c,v) = nzcv a b in n = v`;

val word_ls_def = Define`
  word_ls a b = let (n,z,c,v) = nzcv a b in ~c \/ z`;

val word_hi_def = Define`
  word_hi a b = let (n,z,c,v) = nzcv a b in c /\ ~z`;

val word_lo_def = Define`
  word_lo a b = let (n,z,c,v) = nzcv a b in ~c`;

val word_hs_def = Define`
  word_hs a b = let (n,z,c,v) = nzcv a b in c`;

val _ = overload_on ("<",  Term`word_lt`);
val _ = overload_on (">",  Term`word_gt`);
val _ = overload_on ("<=", Term`word_le`);
val _ = overload_on (">=", Term`word_ge`);
val _ = overload_on ("<=+",Term`word_ls`);
val _ = overload_on (">+", Term`word_hi`);
val _ = overload_on ("<+", Term`word_lo`);
val _ = overload_on (">=+",Term`word_hs`);

val _ = add_infix("<+", 450,HOLgrammars.RIGHT);
val _ = add_infix(">+", 450,HOLgrammars.RIGHT);
val _ = add_infix("<=+",450,HOLgrammars.RIGHT);
val _ = add_infix(">=+",450,HOLgrammars.RIGHT);

(* ------------------------------------------------------------------------- *)
(*  Theorems                                                                 *)
(* ------------------------------------------------------------------------- *)

val ZERO_LT_dimword = store_thm(
  "ZERO_LT_dimword",
  `0 < dimword(:'a)`,
  SRW_TAC [][dimword_def])
val _ = export_rewrites ["ZERO_LT_dimword"]

val dimword_IS_TWICE_INT_MIN = store_thm(
  "dimword_IS_TWICE_INT_MIN",
  `dimword(:'a) = 2 * INT_MIN(:'a)`,
  SRW_TAC [][dimword_def,INT_MIN_def] THEN
  `0 < dimindex (:'a)` by (ASSUME_TAC DIMINDEX_GE_1 THEN DECIDE_TAC) THEN
  Cases_on `dimindex(:'a)` THEN1 FULL_SIMP_TAC (srw_ss()) [] THEN
  SRW_TAC [][EXP]);

val DIMINDEX_GT_0 = save_thm("DIMINDEX_GT_0",
  PROVE [DECIDE ``!s. 1 <= s ==> 0 < s``,DIMINDEX_GE_1] ``0 < dimindex(:'a)``);

val ONE_LT_dimword = store_thm(
  "ONE_LT_dimword",
  `1 < dimword(:'a)`,
  METIS_TAC [dimword_def,DIMINDEX_GT_0,EXP,EXP_BASE_LT_MONO,DECIDE ``1 < 2``]);
val _ = export_rewrites ["ONE_LT_dimword"]

val DIMINDEX_LT =
  (GEN_ALL o CONJUNCT2 o SPEC_ALL o SIMP_RULE bool_ss [DIMINDEX_GT_0] o
   SPEC `^WL`) DIVISION;

val EXISTS_HB = save_thm("EXISTS_HB",
  PROVE [DIMINDEX_GT_0,LESS_ADD_1,ADD1,ADD] ``?m. ^WL = SUC m``);

val MOD_DIMINDEX = store_thm("MOD_DIMINDEX",
  `!n. n MOD dimword (:'a) = BITS (^WL - 1) 0 n`,
  STRIP_ASSUME_TAC EXISTS_HB \\ ASM_SIMP_TAC arith_ss [dimword_def,BITS_ZERO3]);

val SUB1_SUC = DECIDE (Term `!n. 0 < n ==> (SUC (n - 1) = n)`);
val SUB_SUC1 = DECIDE (Term `!n. ~(n = 0) ==> (SUC (n - 1) = n)`);
val SUC_SUB2 = DECIDE (Term `!n. ~(n = 0) ==> (SUC n - 2 = n - 1)`);

val MOD_2EXP_DIMINDEX = save_thm("MOD_2EXP_DIMINDEX",
  SIMP_RULE std_ss [SUB1_SUC,BITS_ZERO3,DIMINDEX_GT_0,GSYM MOD_2EXP_def]
     MOD_DIMINDEX);

val INT_MIN_SUM = store_thm("INT_MIN_SUM",
  `INT_MIN (:('a+'b)) =
     if FINITE (UNIV:'a->bool) /\ FINITE (UNIV:'b->bool) then
       dimword (:'a) * INT_MIN (:'b)
     else
       INT_MIN (:('a+'b))`,
  SRW_TAC [ARITH_ss] [LESS_EQ_ADD_SUB,DIMINDEX_GE_1,EXP_ADD,INT_MIN_def,
    dimword_def,index_sum]);

(* ------------------------------------------------------------------------- *)
(*  Domain transforming maps : theorems                                      *)
(* ------------------------------------------------------------------------- *)

val WORD_ss = rewrites [w2n_def,n2w_def];

val SUM_SLICE = prove(
  `!n x. SUM n (\i. SLICE i i x) = x MOD 2 ** n`,
  Induct \\ ASM_SIMP_TAC arith_ss [SUM_def]
    \\ Cases_on `n`
    \\ SIMP_TAC arith_ss [GSYM BITS_ZERO3,GSYM SLICE_ZERO_THM,
         ONCE_REWRITE_RULE [ADD_COMM] SLICE_COMP_THM]);

val SUM_SBIT_LT = prove(
  `!n f. SUM n (\i. SBIT (f i) i) < 2 ** n`,
  Induct \\ ASM_SIMP_TAC arith_ss [SUM_def,ZERO_LT_TWOEXP]
    \\ STRIP_TAC \\ `SBIT (f n) n <= 2 ** n` by RW_TAC arith_ss [SBIT_def]
    \\ METIS_TAC [EXP,DECIDE ``!a b c. a <= b /\ c < b ==> a + c < 2 * b``]);

val w2n_n2w_lem = prove(
  `!n. SUM ^WL (\i. SBIT ((FCP i. BIT i n):'a word ' i) i) =
       SUM ^WL (\i. SLICE i i n)`,
  STRIP_TAC \\ REWRITE_TAC [SUM] \\ MATCH_MP_TAC GSUM_FUN_EQUAL
    \\ RW_TAC (fcp_ss++ARITH_ss) [BIT_SLICE_THM]);

val w2n_n2w = store_thm("w2n_n2w",
  `!n. w2n (n2w:num->('a word) n) = n MOD (dimword(:'a))`,
  SIMP_TAC (fcp_ss++WORD_ss) [w2n_n2w_lem,SUM_SLICE, dimword_def]);
val _ = export_rewrites ["w2n_n2w"]

val n2w_w2n_lem = prove(
  `!n f i. BIT i (SUM n (\j. SBIT (f j) j)) = f i /\ i < n`,
  Induct \\ ASM_SIMP_TAC arith_ss [SUM_def,BIT_ZERO]
    \\ REPEAT STRIP_TAC \\ Cases_on `i < n`
    \\ FULL_SIMP_TAC arith_ss [NOT_LESS,prim_recTheory.LESS_THM]
    << [
      IMP_RES_TAC LESS_ADD_1
        \\ `SBIT (f n) n = (if f n then 1 else 0) * 2 ** p * 2 ** (SUC i)`
        by RW_TAC (std_ss++numSimps.ARITH_AC_ss) [SBIT_def,EXP_ADD,EXP]
        \\ FULL_SIMP_TAC std_ss [BITS_SUM2,BIT_def],
      PAT_ASSUM `!f i. P` (SPECL_THEN [`f`,`i`] ASSUME_TAC)
        \\ `SUM n (\i. SBIT (f i) i) < 2 ** n` by METIS_TAC [SUM_SBIT_LT]
        \\ IMP_RES_TAC LESS_EQUAL_ADD
        \\ `SBIT (f n) n = (if f n then 1 else 0) * 2 ** n`
        by RW_TAC arith_ss [SBIT_def]
        \\ ASM_SIMP_TAC std_ss [BITS_SUM,
             (GSYM o REWRITE_RULE [LESS_EQ_REFL] o
              SPECL [`p`,`n + p`,`n`]) BIT_OF_BITS_THM]
        \\ FULL_SIMP_TAC std_ss [BIT_def,BITS_COMP_THM2]
        \\ Cases_on `p = 0` \\ RW_TAC std_ss [BITS_ZERO2]
        \\ ASM_SIMP_TAC arith_ss [GSYM BIT_def,BIT_B,BIT_B_NEQ]]);

val n2w_w2n = store_thm("n2w_w2n",
  `!w. n2w (w2n (w:'a word)) = w`,
  SIMP_TAC (fcp_ss++WORD_ss) [n2w_w2n_lem]);
val _ = export_rewrites ["n2w_w2n"]

val word_nchotomy = store_thm("word_nchotomy",
  `!w. ?n. w = n2w n`, PROVE_TAC [n2w_w2n]);

fun Cases_on_word tm = FULL_STRUCT_CASES_TAC (SPEC tm word_nchotomy);
fun Cases_word (g as (_,w)) =
  let val (Bvar,_) = with_exn dest_forall w (ERR "Cases_word" "not a forall")
  in (STRIP_TAC \\ STRUCT_CASES_TAC (Thm.SPEC Bvar word_nchotomy)) g
  end

val n2w_mod = store_thm("n2w_mod",
  `!n. n2w:num -> 'a word (n MOD dimword(:'a)) = n2w n`,
  RW_TAC fcp_ss [dimword_def]
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ ASM_SIMP_TAC (fcp_ss++ARITH_ss)
         [n2w_def,MIN_DEF,BIT_def,GSYM BITS_ZERO3,BITS_COMP_THM2]);

val n2w_11 = store_thm("n2w_11",
  `!m n. ((n2w m):'a word = n2w n) = (m MOD dimword(:'a) = n MOD dimword(:'a))`,
  NTAC 2 STRIP_TAC
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ ASM_SIMP_TAC (fcp_ss++WORD_ss) [GSYM BITS_ZERO3,dimword_def]
    \\ EQ_TAC \\ RW_TAC arith_ss [DECIDE ``i < SUC p = i <= p``]
    \\ PROVE_TAC [(REWRITE_RULE [ZERO_LESS_EQ] o SPECL [`p`,`0`]) BIT_BITS_THM]
);
val _ = export_rewrites ["n2w_11"]

val ranged_word_nchotomy = store_thm("ranged_word_nchotomy",
  `!w:'a word. ?n. (w = n2w n) /\ n < dimword(:'a)`,
  STRIP_TAC
    \\ Q.ISPEC_THEN `w` STRUCT_CASES_TAC word_nchotomy
    \\ SIMP_TAC (srw_ss()) [n2w_11]
    \\ Q.EXISTS_TAC `n MOD dimword(:'a)`
    \\ SIMP_TAC (srw_ss()) [dimword_def, MOD_MOD, DIVISION])

val w2n_11 = store_thm("w2n_11",
  `!v w. (w2n v = w2n w) = (v = w)`,
  REPEAT Cases_word
    \\ REWRITE_TAC [w2n_n2w,n2w_11]);
val _ = export_rewrites ["w2n_11"]

val w2n_lt = store_thm("w2n_lt",
  `!w:'a word. w2n w < dimword(:'a)`,
  SIMP_TAC std_ss [w2n_def,SUM_SBIT_LT,dimword_def]);

val word_0_n2w = store_thm("word_0_n2w",
  `w2n 0w = 0`, SIMP_TAC arith_ss [w2n_n2w, ZERO_LT_dimword]);

val word_1_n2w = store_thm("word_1_n2w",
  `w2n 1w = 1`, SIMP_TAC arith_ss [w2n_n2w, ONE_LT_dimword]);

val w2n_eq_0 = store_thm("w2n_eq_0",
  `(w2n w = 0) = (w = 0w)`,
  Q.SPEC_THEN `w` STRUCT_CASES_TAC word_nchotomy \\ SRW_TAC [][]);

val _ = export_rewrites ["w2n_eq_0"];

val word_add_n2w = store_thm("word_add_n2w",
  `!m n. n2w m + n2w n = n2w (m + n)`,
  SIMP_TAC fcp_ss [word_add_def,w2n_n2w] \\ ONCE_REWRITE_TAC [GSYM n2w_mod]
    \\ SIMP_TAC arith_ss [MOD_PLUS, ZERO_LT_dimword]);

val word_mul_n2w = store_thm("word_mul_n2w",
  `!m n. n2w m * n2w n = n2w (m * n)`,
  SIMP_TAC fcp_ss [word_mul_def,w2n_n2w] \\ ONCE_REWRITE_TAC [GSYM n2w_mod]
    \\ SIMP_TAC arith_ss [MOD_TIMES2,ZERO_LT_dimword]);

val word_log2_n2w = store_thm("word_log2_n2w",
  `!n. word_log2 (n2w n):'a word = n2w (LOG2 (n MOD dimword(:'a)))`,
  SIMP_TAC fcp_ss [word_log2_def,w2n_n2w]);

val top = ``2 ** wl``;

val BITWISE_ONE_COMP_THM = prove(
  `!wl a b. 0 < wl ==>
     (BITWISE wl (\x y. ~x) a b = ^top - 1 - a MOD ^top)`,
  REPEAT STRIP_TAC
    \\ `?b. wl = SUC b` by PROVE_TAC [LESS_ADD_1,ADD1,ADD]
    \\ ASM_SIMP_TAC bool_ss [BITWISE_ONE_COMP_LEM,BITS_ZERO3]);

val ONE_COMP_THM = prove(
  `!wl a x. 0 < wl /\ x < wl ==> (BIT x (^top - 1 - a MOD ^top) = ~BIT x a)`,
  REPEAT STRIP_TAC \\ IMP_RES_TAC (GSYM BITWISE_ONE_COMP_THM)
    \\ ASM_REWRITE_TAC []
    \\ ASM_SIMP_TAC bool_ss [BITWISE_THM]);

val word_1comp_n2w = store_thm("word_1comp_n2w",
  `!n. ~(n2w n):'a word  = n2w (dimword(:'a) - 1 - n MOD dimword(:'a))`,
  RW_TAC fcp_ss [word_1comp_def,n2w_def,ONE_COMP_THM,DIMINDEX_GT_0,dimword_def]);

val word_2comp_n2w = store_thm("word_2comp_n2w",
  `!n. $- (n2w n):'a word  = n2w (dimword(:'a) - n MOD dimword(:'a))`,
  SIMP_TAC std_ss [word_2comp_def,n2w_11,w2n_n2w]);

val word_lsb = store_thm("word_lsb",
  `word_lsb = word_bit 0`,
  SRW_TAC [fcpLib.FCP_ss] [FUN_EQ_THM, word_lsb_def, word_bit_def]);

val word_msb = store_thm("word_msb",
  `word_msb:'a word->bool = word_bit (dimindex(:'a) - 1)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [FUN_EQ_THM, word_msb_def, word_bit_def]);

val word_lsb_n2w = store_thm("word_lsb_n2w",
  `!n. word_lsb ((n2w n):'a word)  = ODD n`,
  SIMP_TAC fcp_ss [word_lsb_def,n2w_def,DIMINDEX_GT_0,LSB_ODD, GSYM LSB_def]);

val word_msb_n2w = store_thm("word_msb_n2w",
  `!n. word_msb ((n2w n):'a word)  = BIT ^HB n`,
  SIMP_TAC (fcp_ss++ARITH_ss) [word_msb_def,n2w_def,DIMINDEX_GT_0]);

val word_msb_n2w_numeric = store_thm(
  "word_msb_n2w_numeric",
  `word_msb (n2w n : 'a word) = INT_MIN(:'a) <= n MOD dimword(:'a)`,
  `dimword(:'a) = 2 * INT_MIN(:'a)` by ACCEPT_TAC dimword_IS_TWICE_INT_MIN THEN
  Q.ABBREV_TAC `WL = dimword (:'a)` THEN
  `0 < WL` by SRW_TAC [][Abbr`WL`, DIMINDEX_GT_0] THEN
  `(n = (n DIV WL) * WL + n MOD WL) /\ n MOD WL < WL`
     by METIS_TAC [DIVISION] THEN
  Q.ABBREV_TAC `q = n DIV WL` THEN
  Q.ABBREV_TAC `r = n MOD WL` THEN
  ASM_SIMP_TAC (srw_ss())[word_msb_n2w, bitTheory.BIT_def, bitTheory.BITS_def,
             MOD_2EXP_def, DIV_2EXP_def, DECIDE ``SUC x - x = 1``, EQ_IMP_THM]
  THEN REPEAT STRIP_TAC
  THENL [
    SPOSE_NOT_THEN ASSUME_TAC THEN
    `r < INT_MIN(:'a)` by SRW_TAC [ARITH_ss][Abbr`r`] THEN
    `n DIV INT_MIN(:'a) = 2 * q`
       by (SRW_TAC [][] THEN METIS_TAC [DIV_MULT,
                                        MULT_COMM,
                                        MULT_ASSOC]) THEN
    METIS_TAC [DECIDE ``~(0n = 1) /\ 0 < 2n``, MOD_EQ_0, MULT_COMM, INT_MIN_def],

    MATCH_MP_TAC MOD_UNIQUE THEN
    Q.EXISTS_TAC `q` THEN ASM_SIMP_TAC (srw_ss()) [] THEN
    MATCH_MP_TAC DIV_UNIQUE THEN
    Q.EXISTS_TAC `r - INT_MIN(:'a)` THEN
    FULL_SIMP_TAC (srw_ss() ++ ARITH_ss) [INT_MIN_def]
  ])

val word_and_n2w = store_thm("word_and_n2w",
  `!n m. (n2w n):'a word && (n2w m) = n2w (BITWISE ^WL (/\) n m)`,
  SIMP_TAC fcp_ss [word_and_def,n2w_11,n2w_def,BITWISE_THM]);

val word_or_n2w = store_thm("word_or_n2w",
  `!n m. (n2w n):'a word !! (n2w m) = n2w (BITWISE ^WL (\/) n m)`,
  SIMP_TAC fcp_ss [word_or_def,n2w_11,n2w_def,BITWISE_THM]);

val word_xor_n2w = store_thm("word_xor_n2w",
  `!n m. (n2w n):'a word ?? (n2w m) =
     n2w (BITWISE ^WL (\x y. ~(x = y)) n m)`,
  SIMP_TAC fcp_ss [word_xor_def,n2w_11,n2w_def,BITWISE_THM]);

(* ------------------------------------------------------------------------- *)
(*  The Boolean operations : theorems                                        *)
(* ------------------------------------------------------------------------- *)

val ONE_COMP_0_THM =
  (SIMP_RULE arith_ss [BIT_ZERO,ZERO_MOD,ZERO_LT_TWOEXP] o
   SPECL [`wl`,`0`]) ONE_COMP_THM;

val word_0 = store_thm("word_0",
  `!i. i < ^WL ==> ~((0w:'a word) ' i)`,
  SIMP_TAC fcp_ss [n2w_def,BIT_ZERO]);

val word_T = store_thm("word_T",
  `!i. i < ^WL ==> (Tw:'a word) ' i`,
  SIMP_TAC fcp_ss [word_T_def,n2w_def,ONE_COMP_0_THM,DIMINDEX_GT_0,
                   UINT_MAX_def, dimword_def]);

val word_L = store_thm("word_L",
  `!n. n < dimindex(:'a) ==> (INT_MINw:'a word ' n = (n = dimindex(:'a) - 1))`,
  SRW_TAC [fcpLib.FCP_ss] [word_L_def, n2w_def, INT_MIN_def]
    \\ Cases_on `n = dimindex (:'a) - 1`
    \\ SRW_TAC [] [BIT_B_NEQ, BIT_B]);

val word_H = store_thm("word_H",
  `!n. n < dimindex(:'a) ==> (INT_MAXw:'a word ' n = (n < dimindex(:'a) - 1))`,
  SRW_TAC [fcpLib.FCP_ss] [word_H_def, n2w_def, INT_MAX_def, INT_MIN_def]
    \\ Cases_on `n < dimindex (:'a) - 1`
    \\ SRW_TAC [] [BIT_B_NEQ, BIT_B, BIT_EXP_SUB1]);

val word_L2 = store_thm("word_L2",
  `word_L2:'a word = if 1 < dimindex(:'a) then 0w else word_L`,
  SRW_TAC []
        [GSYM EXP_ADD, word_L2_def, word_L_def, INT_MIN_def, word_mul_n2w]
    \\ FULL_SIMP_TAC arith_ss [ZERO_LT_dimword, dimword_def,
         DECIDE ``~(1 < n) = (n = 0) \/ (n = 1)``]
    \\ IMP_RES_TAC LESS_ADD_1
    \\ SRW_TAC [ARITH_ss] [LEFT_ADD_DISTRIB]
    \\ SIMP_TAC bool_ss [TIMES2, EXP_ADD, GSYM MULT_ASSOC,
          GSYM MOD_COMMON_FACTOR, ZERO_LT_TWOEXP]
    \\ SRW_TAC [] [MOD_EQ_0,  MULT_ASSOC,  ZERO_LT_TWOEXP]);

val WORD_NEG_1 = store_thm("WORD_NEG_1",
  `$- 1w:'a word = Tw:'a word`,
  REWRITE_TAC [word_T_def,word_2comp_def,w2n_n2w,UINT_MAX_def]
    \\ Cases_on `dimword (:'a) = 1`
    >> ASM_SIMP_TAC arith_ss [n2w_11]
    \\ ASM_SIMP_TAC arith_ss [DECIDE ``0 < x /\ ~(x = 1) ==> 1 < x``,
         LESS_MOD,ZERO_LT_TWOEXP,dimword_def]);

val WORD_MSB_1COMP = store_thm("WORD_MSB_1COMP",
  `!w. word_msb ~w = ~word_msb w`,
  SRW_TAC [fcpLib.FCP_ss] [DIMINDEX_GT_0,word_msb_def,word_1comp_def]);

val WORD_ss =
  rewrites [word_1comp_def,word_and_def,word_or_def,word_xor_def,
    word_0,word_T];

val BOOL_WORD_TAC = SIMP_TAC (fcp_ss++WORD_ss) [] \\ DECIDE_TAC;

val WORD_NOT_NOT = store_thm("WORD_NOT_NOT",
  `!a:'a word. ~(~a) = a`, BOOL_WORD_TAC);

val WORD_DE_MORGAN_THM = store_thm("WORD_DE_MORGAN_THM",
  `!a b. (~(a && b) = ~a !! ~b) /\ (~(a !! b) = ~a && ~b)`, BOOL_WORD_TAC);

val WORD_AND_CLAUSES = store_thm("WORD_AND_CLAUSES",
  `!a:'a word.
      (Tw && a = a) /\ (a && Tw = a) /\
      (0w && a = 0w) /\ (a && 0w = 0w) /\
      (a && a = a)`, BOOL_WORD_TAC);

val WORD_OR_CLAUSES = store_thm("WORD_OR_CLAUSES",
  `!a:'a word.
      (Tw !! a = Tw) /\ (a !! Tw = Tw) /\
      (0w !! a = a) /\ (a !! 0w = a) /\
      (a !! a = a)`, BOOL_WORD_TAC);

val WORD_XOR_CLAUSES = store_thm("WORD_XOR_CLAUSES",
  `!a:'a word.
      (Tw ?? a = ~a) /\ (a ?? Tw = ~a) /\
      (0w ?? a = a) /\ (a ?? 0w = a) /\
      (a ?? a = 0w)`, BOOL_WORD_TAC);

val WORD_AND_ASSOC = store_thm("WORD_AND_ASSOC",
  `!a b c. (a && b) && c = a && b && c`, BOOL_WORD_TAC);

val WORD_OR_ASSOC = store_thm("WORD_OR_ASSOC",
  `!a b c. (a !! b) !! c = a !! b !! c`, BOOL_WORD_TAC);

val WORD_XOR_ASSOC = store_thm("WORD_XOR_ASSOC",
  `!a b c. (a ?? b) ?? c = a ?? b ?? c`, BOOL_WORD_TAC);

val WORD_AND_COMM = store_thm("WORD_AND_COMM",
  `!a b. a && b = b && a`, BOOL_WORD_TAC);

val WORD_OR_COMM = store_thm("WORD_OR_COMM",
  `!a b. a !! b = b !! a`, BOOL_WORD_TAC);

val WORD_XOR_COMM = store_thm("WORD_XOR_COMM",
  `!a b. a ?? b = b ?? a`, BOOL_WORD_TAC);

val WORD_AND_IDEM = store_thm("WORD_AND_IDEM",
  `!a. a && a = a`, BOOL_WORD_TAC);

val WORD_OR_IDEM = store_thm("WORD_OR_IDEM",
  `!a. a !! a = a`, BOOL_WORD_TAC);

val WORD_AND_ABSORD = store_thm("WORD_AND_ABSORD",
  `!a b. a !! a && b = a`, BOOL_WORD_TAC);

val WORD_OR_ABSORB = store_thm("WORD_OR_ABSORB",
  `!a b. a && (a !! b) = a`, BOOL_WORD_TAC);

val WORD_AND_COMP = store_thm("WORD_AND_COMP",
  `!a. a && ~a = 0w`, BOOL_WORD_TAC);

val WORD_OR_COMP = store_thm("WORD_OR_COMP",
  `!a. a !! ~a = Tw`, BOOL_WORD_TAC);

val WORD_XOR_COMP = store_thm("WORD_XOR_COMP",
  `!a. a ?? ~a = Tw`, BOOL_WORD_TAC);

val WORD_RIGHT_AND_OVER_OR = store_thm("WORD_RIGHT_AND_OVER_OR",
  `!a b c. (a !! b) && c = a && c !! b && c`, BOOL_WORD_TAC);

val WORD_RIGHT_OR_OVER_AND = store_thm("WORD_RIGHT_OR_OVER_AND",
  `!a b c. (a && b) !! c = (a !! c) && (b !! c)`, BOOL_WORD_TAC);

val WORD_LEFT_AND_OVER_OR = store_thm("WORD_LEFT_AND_OVER_OR",
  `!a b c. a && (b !! c) = a && b !! a && c`, BOOL_WORD_TAC);

val WORD_LEFT_OR_OVER_AND = store_thm("WORD_LEFT_OR_OVER_AND",
  `!a b c. a !! b && c = (a !! b) && (a !! c)`, BOOL_WORD_TAC);

val WORD_XOR = store_thm("WORD_XOR",
  `!a b. a ?? b = a && ~b !! b && ~a`, BOOL_WORD_TAC);

val ADD_OR_lem_ = prove(
  `!a b n. ~BIT n a \/ ~BIT n b ==>
      (SBIT (BIT n a \/ BIT n b) n = SBIT (BIT n a) n + SBIT (BIT n b) n)`,
  SRW_TAC [] [SBIT_def] \\ FULL_SIMP_TAC std_ss []);

val ADD_OR_lem = prove(
  `!n a b. (!i. i < n ==> ~BIT i a \/ ~BIT i b) ==>
      (SUM n (\i. SBIT (BIT i a) i) + SUM n (\i. SBIT (BIT i b) i) =
       BITWISE n $\/ a b)`,
  Induct \\ SRW_TAC [ARITH_ss] [BITWISE_def, sum_numTheory.SUM_def]
    \\ REWRITE_TAC [ADD_ASSOC]
    \\ METIS_TAC [ADD_OR_lem_, DECIDE ``n < SUC n``]);

val WORD_ADD_OR = store_thm("WORD_ADD_OR",
  `!a b. (a && b = 0w) ==> (a + b = a !! b)`,
  SRW_TAC [fcpLib.FCP_ss] [word_and_def, word_add_def, word_or_def,
         word_0, n2w_def, w2n_def]
    \\ Cases_on_word `a`
    \\ Cases_on_word `b`
    \\ FULL_SIMP_TAC (std_ss++fcpLib.FCP_ss) [n2w_def]
    \\ `!n j. j < dimindex (:'a) ==>
           ((\i'. SBIT ((FCP i. BIT i n):'a word ' i') i') j =
            (\i'. SBIT (BIT i' n) i') j)`
    by SRW_TAC [fcpLib.FCP_ss] []
    \\ POP_ASSUM (fn th => ASSUME_TAC (MATCH_MP SUM_FUN_EQUAL (SPEC `n` th))
                        \\ ASSUME_TAC (MATCH_MP SUM_FUN_EQUAL (SPEC `n'` th)))
    \\ NTAC 2 (POP_ASSUM SUBST1_TAC)
    \\ SRW_TAC [] [ADD_OR_lem, BITWISE_THM]);

(* ------------------------------------------------------------------------- *)
(*  Bit field operations : theorems                                          *)
(* ------------------------------------------------------------------------- *)

val w2w = store_thm("w2w",
  `!w:'a word i. i < dimindex (:'b) ==>
      ((w2w w):'b word ' i = i < ^WL /\ w ' i)`,
  Cases_word \\ SIMP_TAC std_ss [w2w_def,w2n_n2w]
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ STRIP_ASSUME_TAC (Thm.INST_TYPE [alpha |-> beta] EXISTS_HB)
    \\ RW_TAC (fcp_ss++ARITH_ss) [n2w_def,BIT_def,BITS_COMP_THM2,
         GSYM BITS_ZERO3, dimword_def]
    \\ Cases_on `i < SUC m`
    \\ ASM_SIMP_TAC (fcp_ss++ARITH_ss) [MIN_DEF,BITS_ZERO]);

val sw2sw = store_thm("sw2sw",
  `!w:'a word i. i < dimindex(:'b) ==>
     (sw2sw w :'b word ' i =
       if i < dimindex (:'a) \/ dimindex(:'b) < dimindex(:'a) then
         w ' i
       else
         word_msb w)`,
  STRIP_TAC \\ ISPEC_THEN `w` FULL_STRUCT_CASES_TAC ranged_word_nchotomy
    \\ SRW_TAC [ARITH_ss,fcpLib.FCP_ss] [sw2sw_def, w2n_n2w, n2w_def,
         word_msb_n2w, BIT_SIGN_EXTEND, DIMINDEX_GT_0]
    \\ FULL_SIMP_TAC arith_ss [dimword_def, BIT_SIGN_EXTEND, DIMINDEX_GT_0]);

val WORD_ss = rewrites [word_extract_def, word_slice_def,word_bits_def,
  word_bit_def,word_lsl_def,word_lsr_def,word_and_def,word_or_def,word_xor_def,
  word_reverse_def,word_modify_def,n2w_def,w2w,sw2sw,word_msb_def,
  SUC_SUB1,BIT_SLICE_THM4];

val FIELD_WORD_TAC = RW_TAC (fcp_ss++WORD_ss++ARITH_ss) [];

val w2w_id = store_thm("w2w_id",
  `!w:'a word. w2w w:'a word = w`, FIELD_WORD_TAC);

val sw2sw_id = store_thm("sw2sw_id",
  `!w:'a word. sw2sw w:'a word = w`, FIELD_WORD_TAC);

val w2w_w2w = store_thm("w2w_w2w",
  `!w:'a word. (w2w ((w2w w):'b word)):'c word =
        w2w ((dimindex (:'b) - 1 -- 0) w)`,
  FIELD_WORD_TAC
    \\ Cases_on `i < ^WL` \\ FIELD_WORD_TAC
    \\ Cases_on `i < dimindex (:'b)` \\ FIELD_WORD_TAC
    \\ PROVE_TAC [DECIDE ``0 < n /\ ~(i < n) ==> ~(i <= n - 1)``,
         DIMINDEX_GT_0]);

val sw2sw_sw2sw_lem = prove(
  `!w:'a word. ~(dimindex(:'b) < dimindex(:'a) /\
                 dimindex(:'b) < dimindex(:'c)) ==>
       (sw2sw ((sw2sw w):'b word) :'c word = sw2sw w)`,
  FIELD_WORD_TAC
    \\ FIELD_WORD_TAC
    \\ FULL_SIMP_TAC arith_ss [sw2sw,DIMINDEX_GT_0,NOT_LESS]
    \\ FIELD_WORD_TAC
    \\ `dimindex (:'b) = dimindex (:'a)` by DECIDE_TAC
    \\ ASM_REWRITE_TAC []);

val sw2sw_sw2sw_lem2 = prove(
  `!w:'a word. dimindex(:'b) < dimindex(:'a) /\
               dimindex(:'b) < dimindex(:'c) ==>
       (sw2sw ((sw2sw w):'b word) :'c word =
        sw2sw (w2w w :'b word))`,
  FIELD_WORD_TAC
    \\ ASM_SIMP_TAC arith_ss [sw2sw,w2w,DIMINDEX_GT_0,
         DECIDE ``0 < b ==> (1 + (b - 1) = b) /\ (i <= b - 1 = i < b)``]);

val sw2sw_sw2sw = store_thm("sw2sw_sw2sw",
  `!w:'a word. (sw2sw ((sw2sw w):'b word)):'c word =
        if dimindex(:'b) < dimindex(:'a) /\ dimindex(:'b) < dimindex(:'c) then
          sw2sw (w2w w : 'b word)
        else
          sw2sw w`,
  STRIP_TAC
    \\ Cases_on `dimindex(:'b) < dimindex(:'a) /\ dimindex(:'b) < dimindex(:'c)`
    \\ ASM_SIMP_TAC std_ss [sw2sw_sw2sw_lem2]
    \\ METIS_TAC [sw2sw_sw2sw_lem]);

val sw2sw_w2w = store_thm("sw2sw_w2w",
  `!w:'a word. (sw2sw w):'b word =
     (if word_msb w then $- 1w << dimindex(:'a) else 0w) !! w2w w`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
          [word_or_def, word_lsl_def, sw2sw, w2w, WORD_NEG_1, word_T, word_0]
    \\ Cases_on `i < dimindex (:'a)`
    \\ SRW_TAC [ARITH_ss] []);

val word_bit = store_thm("word_bit",
  `!w:'a word b.  b < dimindex (:'a) ==>
     (w ' b = word_bit b w)`, RW_TAC arith_ss [word_bit_def]);

val word_slice_n2w = store_thm("word_slice_n2w",
  `!h l n. (h <> l) (n2w n):'a word =
             (n2w (SLICE (MIN h ^HB) l n)):'a word`,
  FIELD_WORD_TAC);

val word_bits_n2w = store_thm("word_bits_n2w",
  `!h l n. (h -- l) (n2w n):'a word =
             (n2w (BITS (MIN h ^HB) l n)):'a word`,
  FIELD_WORD_TAC \\ Cases_on `i + l <= MIN h ^HB`
    \\ FULL_SIMP_TAC (fcp_ss++ARITH_ss) [MIN_DEF,NOT_LESS_EQUAL,
         BIT_OF_BITS_THM,BIT_OF_BITS_THM2]);

val word_bit_n2w = store_thm("word_bit_n2w",
  `!b n. word_bit b ((n2w n):'a word) = b <= ^HB /\ BIT b n`,
  FIELD_WORD_TAC \\ Cases_on `b <= ^HB`
    \\ ASM_SIMP_TAC fcp_ss [DIMINDEX_GT_0,
         DECIDE ``0 < b /\ a <= b - 1 ==> a < b:num``]);

val word_index_n2w = store_thm("word_index_n2w",
  `!n. (n2w n):'a word ' i =
      if i < dimindex (:'a) then
        BIT i n
      else
        (n2w n):'a word ' i`,
  RW_TAC arith_ss [word_bit,word_bit_n2w]);

val MIN_lem = prove(
 `(!m n. MIN m (m + n) = m) /\ !m n. MIN (m + n) m = m`,
  RW_TAC arith_ss [MIN_DEF]);

val MIN_lem2 = prove(
  `MIN a (MIN b (MIN (c + a) (c + b))) = MIN a b`,
  RW_TAC arith_ss [MIN_DEF]);

val MIN_FST = prove(
  `!x y. x <= y ==> (MIN x y = x)`, RW_TAC arith_ss [MIN_DEF]);

val word_bits_w2w = store_thm("word_bits_w2w",
  `!w. (h -- l) (w2w (w:'a word)):'b word =
       w2w ((MIN h (dimindex (:'b) - 1) -- l) w)`,
  Cases_word \\ SIMP_TAC arith_ss [word_bits_n2w,w2w_def,w2n_n2w,dimword_def]
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ STRIP_ASSUME_TAC (Thm.INST_TYPE [alpha |-> beta] EXISTS_HB)
    \\ ASM_SIMP_TAC arith_ss [n2w_11,GSYM BITS_ZERO3,BITS_COMP_THM2,
         AC MIN_ASSOC MIN_COMM,ONCE_REWRITE_RULE [ADD_COMM] MIN_lem,
         MIN_lem2,dimword_def]);

val word_reverse_n2w = store_thm("word_reverse_n2w",
  `!n. word_reverse ((n2w n):'a word) =
         (n2w (BIT_REVERSE ^WL n)):'a word`,
  FIELD_WORD_TAC \\ ASM_SIMP_TAC arith_ss [BIT_REVERSE_THM]);

val word_modify_n2w = store_thm("word_modify_n2w",
  `!f n. word_modify f ((n2w n):'a word) =
         (n2w (BIT_MODIFY ^WL f n)):'a word`,
  FIELD_WORD_TAC \\ ASM_SIMP_TAC arith_ss [BIT_MODIFY_THM]);

val fcp_n2w = store_thm("fcp_n2w",
  `!f. $FCP f = word_modify (\i b. f i) 0w`,
  RW_TAC fcp_ss [word_modify_def]);

val w2n_w2w = store_thm("w2n_w2w",
  `!w:'a word. w2n ((w2w w):'b word) =
      if ^WL <= dimindex (:'b) then
        w2n w
      else
        w2n ((dimindex (:'b) - 1 -- 0) w)`,
  Cases_word
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ STRIP_ASSUME_TAC (Thm.INST_TYPE [alpha |-> beta] EXISTS_HB)
    \\ ASM_SIMP_TAC arith_ss [BITS_COMP_THM2,w2w_def,word_bits_n2w,
          REWRITE_RULE [MOD_DIMINDEX,dimword_def] w2n_n2w]
    \\ RW_TAC arith_ss [MIN_DEF]
    \\ `m' = m` by DECIDE_TAC \\ ASM_REWRITE_TAC []);

val w2w_n2w = store_thm("w2w_n2w",
  `!n. w2w ((n2w n):'a word):'b word =
         if dimindex (:'b) <= ^WL then
           n2w n
         else
           n2w (BITS (^WL - 1) 0 n)`,
  RW_TAC arith_ss [MIN_DEF,MOD_DIMINDEX,BITS_COMP_THM2,w2n_n2w,w2w_def,n2w_11,
                   dimword_def]);

val w2w_0 = store_thm("w2w_0",
  `w2w 0w = 0w`, SRW_TAC [] [BITS_ZERO2, ZERO_LT_dimword, w2w_n2w]);

val word_extract_n2w = save_thm("word_extract_n2w",
  (SIMP_RULE std_ss [BITS_COMP_THM2, word_bits_n2w, w2w_n2w] o
   SPECL [`h`,`l`,`n2w n`] o SIMP_RULE std_ss [FUN_EQ_THM]) word_extract_def);

val word_extract_w2w = store_thm("word_extract_w2w",
  `!w:'a word. dimindex(:'a) <= dimindex(:'b) ==>
      ((h >< l) (w2w w : 'b word) = (h >< l) w : 'c word)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [word_extract_def, w2w, word_bits_def]
    \\ Cases_on `i < dimindex(:'a)`
    \\ Cases_on `i < dimindex(:'b)`
    \\ Cases_on `i + l < dimindex(:'a)`
    \\ Cases_on `i + l < dimindex(:'b)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [w2w]);

val WORD_w2w_EXTRACT = store_thm("WORD_w2w_EXTRACT",
  `!w:'a word. (w2w w):'b word = (dimindex(:'a) - 1 >< 0) w`,
  SRW_TAC [fcpLib.FCP_ss] [word_bits_def,word_extract_def, w2w]
    \\ Cases_on `i < dimindex (:'a)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] []);

val WORD_EQ = store_thm("WORD_EQ",
  `!v:'a word w. (!x. x < ^WL ==> (word_bit x v = word_bit x w)) = (v = w)`,
  REPEAT Cases_word \\ FIELD_WORD_TAC);

val BIT_UPDATE = store_thm("BIT_UPDATE",
  `!n x. (n :+ x) = word_modify (\i b. if i = n then x else b)`,
  SIMP_TAC fcp_ss [FUN_EQ_THM,FCP_UPDATE_def,word_modify_def]
    \\ PROVE_TAC []);

val TWO_EXP_DIMINDEX = prove(
  `2 <= 2 ** ^WL`,
  METIS_TAC [EXP_BASE_LE_MONO, DECIDE ``1 < 2``, EXP_1, DIMINDEX_GE_1])

val lem = GEN_ALL (MATCH_MP LESS_LESS_EQ_TRANS (CONJ
  ((REWRITE_RULE [SUC_SUB,EXP_1] o SPECL [`b`,`b`,`n`]) BITSLT_THM)
  TWO_EXP_DIMINDEX));

val lem2 = GEN_ALL (MATCH_MP LESS_LESS_EQ_TRANS (CONJ
   (DECIDE ``1 < 2``) TWO_EXP_DIMINDEX));

val WORD_BIT_BITS = store_thm("WORD_BIT_BITS",
  `!b w. word_bit b w = ((b -- b) w = 1w)`,
  STRIP_TAC \\ Cases_word
    \\ RW_TAC arith_ss [MIN_DEF,BIT_def,word_bit_n2w,word_bits_n2w,n2w_11,
         LESS_MOD,lem,lem2,dimword_def]
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC arith_ss [MIN_DEF,GSYM BITS_ZERO3,SUC_SUB1,BITS_COMP_THM2]
    \\ Cases_on `b = 0` \\ FULL_SIMP_TAC arith_ss []
    << [`m = 0` by DECIDE_TAC \\ ASM_REWRITE_TAC [],
      Cases_on `m = b` \\ ASM_SIMP_TAC arith_ss [BITS_ZERO]]);

val lem = prove(`MIN d (l1 + MIN h2 d) = MIN (h2 + l1) d`,
  RW_TAC arith_ss [MIN_DEF]);

val WORD_BITS_COMP_THM = store_thm("WORD_BITS_COMP_THM",
  `!h1 l1 h2 l2 w. (h2 -- l2) ((h1 -- l1) w) =
                   ((MIN h1 (h2 + l1)) -- (l2 + l1)) w`,
  REPEAT STRIP_TAC \\ Cases_on_word `w`
    \\ RW_TAC arith_ss [word_bits_n2w,lem,BITS_COMP_THM2,
         AC MIN_ASSOC MIN_COMM]);

val WORD_BITS_EXTRACT = store_thm("WORD_BITS_EXTRACT",
  `!h l w. (h -- l) w = (h >< l) w`,
  SRW_TAC [fcpLib.FCP_ss] [word_bits_def, word_extract_def, w2w]);

val WORD_BITS_LSR = store_thm("WORD_BITS_LSR",
  `!h l w. (h -- l) w >>> n = (h -- (l + n)) w`,
  FIELD_WORD_TAC \\ Cases_on `i + n < dimindex (:'a)`
    \\ ASM_SIMP_TAC (fcp_ss++ARITH_ss) []);

val WORD_BITS_ZERO = store_thm("WORD_BITS_ZERO",
  `!h l w. h < l ==> ((h -- l) w = 0w)`,
  NTAC 2 STRIP_TAC \\ Cases_word
    \\ RW_TAC arith_ss [word_bits_n2w,BITS_ZERO,MIN_DEF]);

val WORD_BITS_ZERO2 = store_thm("WORD_BITS_ZERO2",
  `!h l. (h -- l) 0w = 0w`,
  SIMP_TAC std_ss [word_bits_n2w, BITS_ZERO2]);

val WORD_BITS_ZERO3 = store_thm("WORD_BITS_ZERO3",
  `!h l w:'a word. dimindex(:'a) <= l ==> ((h -- l) w = 0w)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [word_bits_def, word_0]);

val WORD_BITS_LT = store_thm("WORD_BITS_LT",
  `!h l w. w2n ((h -- l) w) < 2 ** (SUC h - l)`,
  NTAC 2 STRIP_TAC \\ Cases_word
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ RW_TAC arith_ss [word_bits_n2w,w2n_n2w,GSYM BITS_ZERO3,
         BITS_COMP_THM2,MIN_DEF,BITSLT_THM,dimword_def]
    \\ FULL_SIMP_TAC std_ss []
    << [`SUC m - l <= SUC h - l` by DECIDE_TAC,
     `SUC (l + m) - l <= SUC h - l` by DECIDE_TAC]
    \\ PROVE_TAC [TWOEXP_MONO2,BITSLT_THM,LESS_LESS_EQ_TRANS]);

val WORD_EXTRACT_ZERO = store_thm("WORD_EXTRACT_ZERO",
  `!h l w. h < l ==> ((h >< l) w = 0w)`,
  SRW_TAC [] [word_extract_def, WORD_BITS_ZERO, w2w_0]);

val WORD_EXTRACT_ZERO2 = store_thm("WORD_EXTRACT_ZERO2",
  `!h l. (h >< l) 0w = 0w`,
  SRW_TAC [] [word_extract_def, WORD_BITS_ZERO2, w2w_0]);

val WORD_EXTRACT_ZERO3 = store_thm("WORD_EXTRACT_ZERO3",
  `!h l w:'a word. dimindex (:'a) <= l ==> ((h >< l) w = 0w)`,
  SRW_TAC [] [word_extract_def, WORD_BITS_ZERO3, w2w_0]);

val WORD_SLICE_THM = store_thm("WORD_SLICE_THM",
  `!h l w. (h <> l) w = (h -- l) w << l`,
  FIELD_WORD_TAC \\ Cases_on `l <= i` \\ ASM_SIMP_TAC arith_ss []);

val WORD_SLICE_ZERO = store_thm("WORD_SLICE_ZERO",
  `!h l w. h < l ==> ((h <> l) w = 0w)`,
  NTAC 2 STRIP_TAC \\ Cases_word
    \\ RW_TAC arith_ss [word_slice_n2w,SLICE_ZERO,MIN_DEF]);

val WORD_SLICE_ZERO2 = save_thm("WORD_SLICE_ZERO2",
  SIMP_CONV std_ss [word_slice_n2w, SLICE_ZERO2] ``(h <> l) 0w``);

val WORD_SLICE_BITS_THM = store_thm("WORD_SLICE_BITS_THM",
  `!h w. (h <> 0) w = (h -- 0) w`, FIELD_WORD_TAC);

val WORD_BITS_SLICE_THM = store_thm("WORD_BITS_SLICE_THM",
  `!h l w. (h -- l) ((h <> l) w) = (h -- l) w`,
  NTAC 2 STRIP_TAC \\ Cases_word
    \\ RW_TAC arith_ss [word_slice_n2w,word_bits_n2w,BITS_SLICE_THM]);

val WORD_SLICE_COMP_THM = store_thm("WORD_SLICE_COMP_THM",
  `!h m' m l w:'a word. l <= m /\ (m' = m + 1) /\ m < h ==>
     (((h <> m') w):'a word !! (m <> l) w =
      ((h <> l) w):'a word)`,
  FIELD_WORD_TAC \\ `i <= m \/ m + 1 <= i` by DECIDE_TAC
    \\ ASM_SIMP_TAC arith_ss []);

val WORD_EXTRACT_COMP_THM = store_thm("WORD_EXTRACT_COMP_THM",
  `!w:'c word. (h >< l) ((m >< n) w :'b word) =
         (MIN m (MIN (h + n)
           (MIN (dimindex(:'c) - 1) (dimindex(:'b) + n - 1))) >< l + n) w`,
  SRW_TAC [fcpLib.FCP_ss] [word_extract_def,word_bits_def,w2w,word_0]
    \\ Cases_on `i < dimindex (:'b)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [w2w]
    \\ Cases_on `i < dimindex (:'c)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [w2w]
    \\ Cases_on `i + l < dimindex (:'b)`
    \\ Cases_on `i + l < dimindex (:'c)`
    \\ Cases_on `i + (l + n) < dimindex (:'c)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [w2w]
    \\ FULL_SIMP_TAC bool_ss [NOT_LESS, NOT_LESS_EQUAL]
    << [
      METIS_TAC [DECIDE ``i + (l + n) <= h + n = i + l <= h:num``],
      `0 < i + l` by METIS_TAC [LESS_LESS_EQ_TRANS,DIMINDEX_GT_0]
        \\ ASM_SIMP_TAC arith_ss []]);

val word_extract = (GSYM o SIMP_RULE std_ss [] o
  REWRITE_RULE [FUN_EQ_THM]) word_extract_def;

val WORD_EXTRACT_BITS_COMP = save_thm("WORD_EXTRACT_BITS_COMP",
 (SIMP_RULE std_ss [word_extract] o
  SIMP_CONV std_ss [word_extract_def,WORD_BITS_COMP_THM])
  ``(j >< k) ((h -- l) n)``);

val WORD_ALL_BITS = store_thm("WORD_ALL_BITS",
  `!w:'a word. (dimindex (:'a) - 1 <= h) ==> ((h -- 0) w = w)`,
  Cases_word 
    \\ SRW_TAC [] [word_bits_n2w,GSYM MOD_DIMINDEX,DIVISION,DIMINDEX_GT_0,
         simpLib.SIMP_PROVE arith_ss [MIN_DEF] ``l <= h ==> (MIN h l = l)``]);

val EXTRACT_ALL_BITS = store_thm("EXTRACT_ALL_BITS",
  `!h w:'a word. dimindex (:'a) - 1 <= h ==> ((h >< 0) w = w2w w)`,
  SRW_TAC [] [word_extract_def, WORD_ALL_BITS]);

val WORD_BITS_MIN_HIGH = store_thm("WORD_BITS_MIN_HIGH",
  `!w:'a word. dimindex(:'a) - 1 < h ==>
     ((h -- l) w = (dimindex(:'a) - 1 -- l) w)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [word_bits_def]
    \\ Cases_on `i + l < dimindex(:'a)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] []);

val WORD_EXTRACT_MIN_HIGH = store_thm("WORD_EXTRACT_MIN_HIGH",
  `(!h l w:'a word.
       dimindex (:'a) <= dimindex (:'b) + l /\ dimindex (:'a) <= h ==>
      (((h >< l) w):'b word = (dimindex (:'a) - 1 >< l) w)) /\
    !h l w:'a word.
       dimindex (:'b) + l < dimindex (:'a) /\ dimindex (:'b) + l <= h ==>
      (((h >< l) w):'b word = (dimindex (:'b) + l - 1 >< l) w)`,
  SRW_TAC [fcpLib.FCP_ss] [word_bits_def,word_extract_def, w2w]
    \\ Cases_on `i < dimindex (:'a)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] []
    \\ Cases_on `i + l < dimindex (:'a)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] []);

val CONCAT_EXTRACT = store_thm("CONCAT_EXTRACT",
  `!h m l w:'a word.
     (h - m = dimindex(:'b)) /\ (m + 1 - l = dimindex(:'c)) /\
     (h + 1 - l = dimindex (:'d)) /\ ~(dimindex(:'b + 'c) = 1) ==>
      (((h >< m + 1) w):'b word @@ ((m >< l) w):'c word =
       ((h >< l) w):'d word)`,
  SRW_TAC [boolSimps.LET_ss,ARITH_ss,fcpLib.FCP_ss]
        [DIMINDEX_GT_0,word_concat_def,word_extract_def,word_join_def,
         w2w,fcpTheory.index_sum,word_bits_def,word_or_def,word_lsl_def]
    \\ PAT_ASSUM `~(x = 1)` (K ALL_TAC)
    \\ Cases_on `dimindex (:'c) <= i`
    \\ ASM_REWRITE_TAC [] \\ FULL_SIMP_TAC std_ss [NOT_LESS_EQUAL]
    \\ Cases_on `i < dimindex (:'a)`
    \\ SRW_TAC [ARITH_ss,fcpLib.FCP_ss] [DIMINDEX_GT_0,w2w]
    \\ FULL_SIMP_TAC arith_ss [DIMINDEX_GT_0,SUB_RIGHT_EQ,NOT_LESS,
         DECIDE ``0 < x ==> (a + (b + c) <= x + c - 1 = a + b <= x - 1)``]
    << [
      METIS_TAC [DIMINDEX_GT_0,NOT_ZERO_LT_ZERO],
      Cases_on `dimindex (:'a) + dimindex (:'c) <= i`
        \\ FULL_SIMP_TAC arith_ss [NOT_LESS_EQUAL]
        \\ `i - dimindex (:'c) < dimindex (:'a)` by DECIDE_TAC
        \\ SRW_TAC [ARITH_ss,fcpLib.FCP_ss] [DIMINDEX_GT_0]]);

val EXTRACT_CONCAT = store_thm("EXTRACT_CONCAT",
  `!v:'a word w:'b word.
     FINITE (UNIV:'a set) /\ FINITE (UNIV:'b set) /\
     dimindex(:'a) + dimindex(:'b) <= dimindex(:'c) ==>
     ((dimindex(:'b) - 1 >< 0)
         ((v @@ w):'c word) = w) /\
     ((dimindex(:'a) + dimindex(:'b) - 1 >< dimindex(:'b))
         ((v @@ w):'c word) = v)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss, boolSimps.LET_ss]
    [word_concat_def, word_extract_def, word_bits_def, word_join_def,
     word_or_def, word_lsl_def, w2w, fcpTheory.index_sum]);

val EXTRACT_JOIN = store_thm("EXTRACT_JOIN",
  `!h m l w:'a word.
       l <= m /\ m' <= h /\ (m' = m + 1) /\ (s = m' - l) ==>
       ((h >< m') w << s !! (m >< l) w =
         (MIN h (MIN (dimindex(:'b) + l - 1)
            (dimindex(:'a) - 1)) >< l) w :'b word)`,
  SRW_TAC [fcpLib.FCP_ss]
         [word_extract_def, word_bits_def, word_or_def, word_lsl_def, w2w]
    \\ Cases_on `i < dimindex (:'a)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
         [w2w, DIMINDEX_GT_0, NOT_LESS, NOT_LESS_EQUAL]
    << [
      Cases_on `i + l <= dimindex (:'a) - 1`
        \\ SRW_TAC [ARITH_ss] []
        \\ Cases_on `m + 1 < i + l`
        \\ SRW_TAC [ARITH_ss] []
        \\ Cases_on `m + 1 = i + l`
        \\ FULL_SIMP_TAC arith_ss [NOT_LESS],
      Cases_on `i + l < m + 1`
        \\ FULL_SIMP_TAC arith_ss [NOT_LESS]
        \\ Cases_on `m + (dimindex (:'a) + 1) <= i + l`
        \\ FULL_SIMP_TAC arith_ss [NOT_LESS_EQUAL]
        \\ `i + l - (m + 1) < dimindex (:'a)` by DECIDE_TAC
        \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] []]);

val EXTRACT_JOIN_ADD = store_thm("EXTRACT_JOIN_ADD",
  `!h m l w:'a word.
       l <= m /\ m' <= h /\ (m' = m + 1) /\ (s = m' - l) ==>
       ((h >< m') w << s + (m >< l) w =
         (MIN h (MIN (dimindex(:'b) + l - 1)
            (dimindex(:'a) - 1)) >< l) w :'b word)`,
  REPEAT STRIP_TAC
    \\ `(h >< m') w << s + (m >< l) w = (h >< m') w << s !! (m >< l) w`
    by (MATCH_MP_TAC WORD_ADD_OR
          \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
               [word_extract_def, word_bits_def, word_lsl_def, word_and_def,
                word_0, w2w, DIMINDEX_GT_0]
          \\ Cases_on `i < dimindex (:'a)`
          \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] []
          \\ Cases_on `m + 1 <= i + l`
          \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [])
    \\ ASM_SIMP_TAC std_ss [EXTRACT_JOIN]);

val WORD_SLICE_OVER_BITWISE = store_thm("WORD_SLICE_OVER_BITWISE",
  `(!h l v:'a word w:'a word.
      (h <> l) v && (h <> l) w = (h <> l) (v && w)) /\
   (!h l v:'a word w:'a word.
      (h <> l) v !! (h <> l) w = (h <> l) (v !! w)) /\
   (!h l v:'a word w:'a word.
      (h <> l) v ?? (h <> l) w = (h <> l) (v ?? w))`,
  FIELD_WORD_TAC << [PROVE_TAC [], PROVE_TAC [], ALL_TAC]
    \\ Cases_on `l <= i /\ i <= h` \\ FULL_SIMP_TAC arith_ss []);

val WORD_BITS_OVER_BITWISE = store_thm("WORD_BITS_OVER_BITWISE",
  `(!h l v:'a word w:'a word.
      (h -- l) v && (h -- l) w = (h -- l) (v && w)) /\
   (!h l v:'a word w:'a word.
      (h -- l) v !! (h -- l) w = (h -- l) (v !! w)) /\
   (!h l v:'a word w:'a word.
      (h -- l) v ?? (h -- l) w = (h -- l) (v ?? w))`,
  FIELD_WORD_TAC
    \\ Cases_on `i + l <= h /\ i + l <= dimindex (:'a) - 1`
    \\ FULL_SIMP_TAC (fcp_ss++ARITH_ss) []);

val WORD_w2w_OVER_BITWISE = store_thm("WORD_w2w_OVER_BITWISE",
  `(!v:'a word w:'a word. w2w v && w2w w = w2w (v && w):'b word) /\
   (!v:'a word w:'a word. w2w v !! w2w w = w2w (v !! w):'b word) /\
   (!v:'a word w:'a word. w2w v ?? w2w w = w2w (v ?? w):'b word)`,
  FIELD_WORD_TAC
    \\ Cases_on `i < dimindex (:'a)`
    \\ FULL_SIMP_TAC (fcp_ss++ARITH_ss) []);

val WORD_EXTRACT_OVER_BITWISE = store_thm("WORD_EXTRACT_OVER_BITWISE",
  `(!h l v:'a word w:'a word.
      (h >< l) v && (h >< l) w = (h >< l) (v && w)) /\
   (!h l v:'a word w:'a word.
      (h >< l) v !! (h >< l) w = (h >< l) (v !! w)) /\
   (!h l v:'a word w:'a word.
      (h >< l) v ?? (h >< l) w = (h >< l) (v ?? w))`,
  SIMP_TAC std_ss
    [word_extract_def, GSYM WORD_BITS_OVER_BITWISE, WORD_w2w_OVER_BITWISE]);

local
  fun Cases_on_word tm =
   Q.ISPEC_THEN tm FULL_STRUCT_CASES_TAC ranged_word_nchotomy;
in
val WORD_w2w_OVER_ADD = Q.store_thm("WORD_w2w_OVER_ADD",
  `!a b:'a word.
     (w2w (a + b) = (dimindex(:'a) - 1 -- 0) (w2w a + w2w b))`,
  REPEAT STRIP_TAC
    \\ Cases_on_word `a:'a word`
    \\ Cases_on_word `b:'a word`
    \\ `n < 2 ** SUC (dimindex (:'a) - 1) /\ n' < 2 ** SUC (dimindex (:'a) - 1)`
    by FULL_SIMP_TAC arith_ss [dimword_def,DIMINDEX_GT_0,
         DECIDE ``0 < n ==> (SUC (n - 1) = n)``]
    \\ SRW_TAC [ARITH_ss] [WORD_w2w_EXTRACT, word_extract_n2w, word_bits_n2w,
         MOD_DIMINDEX, BITS_COMP_THM2, MIN_DEF, BITS_ZEROL, WORD_BITS_EXTRACT]    \\ SRW_TAC [ARITH_ss] [word_add_n2w, word_extract_n2w,  MOD_DIMINDEX,         BITS_COMP_THM2]    \\ SRW_TAC [ARITH_ss] [MIN_DEF]);

val WORD_w2w_OVER_MUL = Q.store_thm("WORD_w2w_OVER_MUL",
  `!a b:'a word.
     (w2w (a * b) = (dimindex(:'a) - 1 -- 0) (w2w a * w2w b))`,
  REPEAT STRIP_TAC
    \\ Cases_on_word `a:'a word`
    \\ Cases_on_word `b:'a word`
    \\ `n < 2 ** SUC (dimindex (:'a) - 1) /\ n' < 2 ** SUC (dimindex (:'a) - 1)`
    by FULL_SIMP_TAC arith_ss [dimword_def,DIMINDEX_GT_0,
         DECIDE ``0 < n ==> (SUC (n - 1) = n)``]
    \\ SRW_TAC [ARITH_ss] [WORD_w2w_EXTRACT, word_extract_n2w, word_bits_n2w,
         MOD_DIMINDEX, BITS_COMP_THM2, MIN_DEF, BITS_ZEROL, WORD_BITS_EXTRACT]
    \\ SRW_TAC [ARITH_ss] [word_mul_n2w, word_extract_n2w,  MOD_DIMINDEX,
         BITS_COMP_THM2]
    \\ SRW_TAC [ARITH_ss] [MIN_DEF]);
end

val BIT_SET_lem_ = prove(
  `!i j n. i < j ==> ~(i IN BIT_SET j n)`,
  completeInduct_on `n` \\ ONCE_REWRITE_TAC [BIT_SET_def]
    \\ SRW_TAC [ARITH_ss] []);

val BIT_SET_lem = prove(
  `!k i n. BIT i n = i + k IN BIT_SET k n`,
  Induct_on `i` \\ ONCE_REWRITE_TAC [BIT_SET_def]
    \\ SRW_TAC [] [BIT_ZERO, GSYM LSB_def, LSB_ODD, BIT_SET_lem_]
    \\ REWRITE_TAC [DECIDE ``SUC a + b = a + SUC b``]
    \\ PAT_ASSUM `!k n. BIT i n = i + k IN BIT_SET k n`
         (fn th => REWRITE_TAC [GSYM th, BIT_DIV2]));

val BIT_SET = save_thm("BIT_SET",
  (REWRITE_RULE [ADD_0] o SPEC `0`) BIT_SET_lem);

val lem = prove(
  `!i a b. MAX (LOG2 a) (LOG2 b) < i ==> ~BIT i a /\ ~BIT i b`,
  SRW_TAC [ARITH_ss] [NOT_BIT_GT_LOG2]);

val lem2 = prove(
  `!i a b. MIN (LOG2 a) (LOG2 b) < i ==> ~BIT i a \/ ~BIT i b`,
  NTAC 2 (SRW_TAC [ARITH_ss] [NOT_BIT_GT_LOG2]));

val bitwise_log_max = prove(
  `!op i l a b. ~(op F F) /\ i < l ==>
       (BIT i (BITWISE l op a b) =
        BIT i (BITWISE (SUC (MAX (LOG2 a) (LOG2 b))) op a b))`,
  REPEAT STRIP_TAC
    \\ Cases_on `l <= SUC (MAX (LOG2 a) (LOG2 b))`
    \\ SRW_TAC [ARITH_ss] [BITWISE_THM]
    \\ Cases_on `i < SUC (MAX (LOG2 a) (LOG2 b))`
    >> ASM_SIMP_TAC std_ss [BITWISE_THM]
    \\ FULL_SIMP_TAC pure_ss [NOT_LESS_EQUAL,NOT_LESS,NOT_BIT_GT_BITWISE]
    \\ `MAX (LOG2 a) (LOG2 b) < i` by DECIDE_TAC
    \\ IMP_RES_TAC lem \\ ASM_SIMP_TAC std_ss []);

val bitwise_log_min = prove(
  `!op i l a b. (!x. ~(op x F) /\ ~(op F x)) /\ i < l ==>
       (BIT i (BITWISE l op a b) =
        BIT i (BITWISE (SUC (MIN (LOG2 a) (LOG2 b))) op a b))`,
  REPEAT STRIP_TAC
    \\ Cases_on `l <= SUC (MIN (LOG2 a) (LOG2 b))`
    \\ SRW_TAC [ARITH_ss] [BITWISE_THM]
    \\ Cases_on `i < SUC (MIN (LOG2 a) (LOG2 b))`
    >> ASM_SIMP_TAC std_ss [BITWISE_THM]
    \\ FULL_SIMP_TAC pure_ss [NOT_LESS_EQUAL,NOT_LESS,NOT_BIT_GT_BITWISE]
    \\ `MIN (LOG2 a) (LOG2 b) < i` by DECIDE_TAC
    \\ IMP_RES_TAC lem2 \\ ASM_SIMP_TAC std_ss []);

val bitwise_log_left = prove(
  `!op i l a b. (!x. ~(op F x)) /\ i < l ==>
       (BIT i (BITWISE l op a b) =
        BIT i (BITWISE (SUC (LOG2 a)) op a b))`,
  REPEAT STRIP_TAC
    \\ Cases_on `l <= SUC (LOG2 a)`
    \\ SRW_TAC [ARITH_ss] [BITWISE_THM]
    \\ Cases_on `i < SUC (LOG2 a)`
    >> ASM_SIMP_TAC std_ss [BITWISE_THM]
    \\ FULL_SIMP_TAC pure_ss [NOT_LESS_EQUAL,NOT_LESS,NOT_BIT_GT_BITWISE]
    \\ `LOG2 a < i` by DECIDE_TAC
    \\ IMP_RES_TAC NOT_BIT_GT_LOG2 \\ ASM_SIMP_TAC std_ss []);

val word_or_n2w_alpha = prove(
  `!n m. n2w n !! n2w m = n2w (BITWISE (SUC (MAX (LOG2 n) (LOG2 m))) $\/ n m)`,
  RW_TAC arith_ss [word_or_n2w, GSYM WORD_EQ, word_bit_n2w, bitwise_log_max]);

val word_and_n2w_alpha = prove(
  `!n m. n2w n && n2w m = n2w (BITWISE (SUC (MIN (LOG2 n) (LOG2 m))) $/\ n m)`,
  RW_TAC arith_ss [word_and_n2w, GSYM WORD_EQ, word_bit_n2w, bitwise_log_min]);

val lem = prove(
  `!n m. n2w n && ~(n2w m) : 'a word =
      n2w (BITWISE (dimindex(:'a)) (\x y. x /\ ~y) n m)`,
  SRW_TAC [fcpLib.FCP_ss] [word_and_def, word_1comp_def, n2w_def, BITWISE_THM]);

val word_and_1comp_n2w_alpha = prove(
  `!n m. n2w n && ~(n2w m) =
      n2w (BITWISE (SUC (LOG2 n)) (\a b. a /\ ~b) n m)`,
  RW_TAC arith_ss [lem, GSYM WORD_EQ, word_bit_n2w, bitwise_log_left]);

val word_and_1comp_n2w_alpha2 = prove(
  `!n m. ~(n2w n) && ~(n2w m) =
      ~(n2w (BITWISE (SUC (MAX (LOG2 n) (LOG2 m))) $\/ n m))`,
  RW_TAC std_ss [GSYM WORD_DE_MORGAN_THM, word_or_n2w_alpha]);

val word_or_1comp_n2w_alpha = prove(
  `!n m. n2w n !! ~(n2w m) =
      ~(n2w (BITWISE (SUC (LOG2 m)) (\a b. a /\ ~b) m n))`,
  RW_TAC std_ss [word_and_1comp_n2w_alpha,
    PROVE [WORD_NOT_NOT, WORD_DE_MORGAN_THM, WORD_AND_COMM]
      ``a !! ~b = ~(b && ~a)``]);

val word_or_1comp_n2w_alpha2 = prove(
  `!n m. ~(n2w n) !! ~(n2w m) =
      ~(n2w (BITWISE (SUC (MIN (LOG2 n) (LOG2 m))) $/\ n m))`,
  RW_TAC std_ss [GSYM WORD_DE_MORGAN_THM, word_and_n2w_alpha]);

val WORD_LITERAL_AND = save_thm("WORD_LITERAL_AND",
  LIST_CONJ
    [word_and_n2w_alpha, word_and_1comp_n2w_alpha,
     ONCE_REWRITE_RULE [WORD_AND_COMM] word_and_1comp_n2w_alpha,
     word_and_1comp_n2w_alpha2]);

val WORD_LITERAL_OR = save_thm("WORD_LITERAL_OR",
  LIST_CONJ
    [word_or_n2w_alpha, word_or_1comp_n2w_alpha,
     ONCE_REWRITE_RULE [WORD_OR_COMM] word_or_1comp_n2w_alpha,
     word_or_1comp_n2w_alpha2]);

(* ------------------------------------------------------------------------- *)
(*  Word arithmetic: theorems                                                *)
(* ------------------------------------------------------------------------- *)

val _ = set_fixity "==" (Infixr 450);

val equiv = ``\x y. x MOD ^top = y MOD ^top``;

val n2w_11' = REWRITE_RULE [dimword_def] n2w_11
val lift_rule = REWRITE_RULE [GSYM n2w_11'] o INST [`wl` |-> `^WL`];
val LET_RULE = CONV_RULE (DEPTH_CONV pairLib.let_CONV);
val LET_TAC = CONV_TAC (DEPTH_CONV pairLib.let_CONV);

val MOD_ADD = (REWRITE_RULE [ZERO_LT_TWOEXP] o SPEC `^top`) MOD_PLUS;
val ONE_LT_EQ_TWOEXP = REWRITE_RULE [SYM ONE,LESS_EQ] ZERO_LT_TWOEXP;

val SUC_EQUIV_mod = LET_RULE (prove(
  `!a b. let $== = ^equiv in
           SUC a == b ==> a == (b + (^top - 1))`,
  LET_TAC \\ REPEAT STRIP_TAC
    \\ ONCE_REWRITE_TAC [GSYM MOD_ADD]
    \\ POP_ASSUM (fn th => REWRITE_TAC [SYM th])
    \\ SIMP_TAC std_ss [MOD_ADD,ADD1,GSYM LESS_EQ_ADD_SUB,ONE_LT_EQ_TWOEXP]
    \\ SIMP_TAC arith_ss [ADD_MODULUS,ZERO_LT_TWOEXP]));

val INV_SUC_EQ_mod = LET_RULE (prove(
  `!m n. let $== = ^equiv in
           (SUC m == SUC n) = (m == n)`,
  LET_TAC \\ REPEAT STRIP_TAC \\ EQ_TAC << [
    STRIP_TAC \\ IMP_RES_TAC SUC_EQUIV_mod
      \\ FULL_SIMP_TAC arith_ss [GSYM LESS_EQ_ADD_SUB,ADD1,ADD_MODULUS,
           ZERO_LT_TWOEXP,ONE_LT_EQ_TWOEXP],
    REWRITE_TAC [ADD1] \\ ONCE_REWRITE_TAC [GSYM MOD_ADD]
      \\ RW_TAC std_ss []]));

val ADD_INV_0_mod = LET_RULE (prove(
  `!m n. let $== = ^equiv in
           (m + n == m) ==> (n == 0)`,
  LET_TAC \\ Induct \\ RW_TAC bool_ss [ADD_CLAUSES]
    \\ FULL_SIMP_TAC bool_ss [INV_SUC_EQ_mod]));

val ADD_INV_0_EQ_mod = LET_RULE (prove(
  `!m n. let $== = ^equiv in
           (m + n == m) = (n == 0)`,
  LET_TAC \\ REPEAT STRIP_TAC \\ EQ_TAC \\ STRIP_TAC
    \\ IMP_RES_TAC ADD_INV_0_mod
    \\ ONCE_REWRITE_TAC [GSYM MOD_ADD]
    \\ ASM_SIMP_TAC arith_ss [ZERO_MOD,ADD_MODULUS,ZERO_LT_TWOEXP]));

val EQ_ADD_LCANCEL_mod = LET_RULE (prove(
  `!m n p. let $== = ^equiv in
           (m + n == m + p) = (n == p)`,
  LET_TAC \\ Induct \\ ASM_REWRITE_TAC [ADD_CLAUSES,INV_SUC_EQ_mod]));

val WORD_NEG_mod = LET_RULE (prove(
  `!n. let $== = ^equiv in
         ^top - n MOD ^top == (^top - 1 - n MOD ^top) + 1`,
  LET_TAC \\ STRIP_TAC
    \\ `1 + n MOD ^top <= ^top`
    by SIMP_TAC std_ss [DECIDE ``a < b ==> 1 + a <= b``,MOD_2EXP_LT]
    \\ ASM_SIMP_TAC arith_ss [SUB_RIGHT_SUB,SUB_RIGHT_ADD]
    \\ Tactical.REVERSE (Cases_on `1 + n MOD ^top = ^top`)
    >> FULL_SIMP_TAC arith_ss []
    \\ RULE_ASSUM_TAC
         (SIMP_RULE bool_ss [GSYM SUC_ONE_ADD,GSYM PRE_SUC_EQ,ZERO_LT_TWOEXP])
    \\ ASM_SIMP_TAC arith_ss [PRE_SUB1]));

val n2w_dimword = prove(
  `n2w (2 ** ^WL) = 0w:'a word`,
  ONCE_REWRITE_TAC [GSYM n2w_mod]
    \\ SIMP_TAC std_ss [DIVMOD_ID,ZERO_MOD,ZERO_LT_TWOEXP,dimword_def]);

val WORD_ss = rewrites [word_add_n2w,word_mul_n2w,word_sub_def,word_2comp_def,
  w2n_n2w,n2w_w2n,word_0,n2w_dimword,ZERO_LT_TWOEXP,dimword_def,
  LEFT_ADD_DISTRIB,RIGHT_ADD_DISTRIB,
  LEFT_SUB_DISTRIB,RIGHT_SUB_DISTRIB];

val ARITH_WORD_TAC =
  REPEAT Cases_word
    \\ ASM_SIMP_TAC (fcp_ss++ARITH_ss++numSimps.ARITH_AC_ss++WORD_ss) [];

(* -- *)

val WORD_ADD_0 = store_thm("WORD_ADD_0",
  `(!w:'a word. w + 0w = w) /\ (!w:'a word. 0w + w = w)`,
   CONJ_TAC \\ ARITH_WORD_TAC);

val WORD_ADD_ASSOC = store_thm("WORD_ADD_ASSOC",
  `!v:'a word w x. v + (w + x) = v + w + x`, ARITH_WORD_TAC);

val WORD_MULT_ASSOC = store_thm("WORD_MULT_ASSOC",
  `!v:'a word w x. v * (w * x) = v * w * x`,
  REPEAT Cases_word \\ ASM_SIMP_TAC (fcp_ss++WORD_ss) [MULT_ASSOC]);

val WORD_ADD_COMM = store_thm("WORD_ADD_COMM",
  `!v:'a word w. v + w = w + v`, ARITH_WORD_TAC);

val WORD_MULT_COMM = store_thm("WORD_MULT_COMM",
  `!v:'a word w. v * w = w * v`, ARITH_WORD_TAC);

val WORD_MULT_CLAUSES = store_thm("WORD_MULT_CLAUSES",
  `!v:'a word w.
     (0w * v = 0w) /\ (v * 0w = 0w) /\
     (1w * v = v) /\ (v * 1w = v) /\
     ((v + 1w) * w = v * w + w) /\ (v * (w + 1w) = v + v * w)`,
  ARITH_WORD_TAC);

val WORD_LEFT_ADD_DISTRIB = store_thm("WORD_LEFT_ADD_DISTRIB",
  `!v:'a word w x. v * (w + x) = v * w + v * x`, ARITH_WORD_TAC);

val WORD_RIGHT_ADD_DISTRIB = store_thm("WORD_RIGHT_ADD_DISTRIB",
  `!v:'a word w x. (v + w) * x = v * x + w * x`, ARITH_WORD_TAC);

val WORD_ADD_SUB_ASSOC = store_thm("WORD_ADD_SUB_ASSOC",
  `!v:'a word w x. v + w - x = v + (w - x)`, ARITH_WORD_TAC);

val WORD_ADD_SUB_SYM = store_thm("WORD_ADD_SUB_SYM",
  `!v:'a word w x. v + w - x = v - x + w`, ARITH_WORD_TAC);

val WORD_ADD_LINV = store_thm("WORD_ADD_LINV",
  `!w:'a word. $- w + w = 0w`,
  ARITH_WORD_TAC
    \\ STRIP_ASSUME_TAC
         ((REWRITE_RULE [ZERO_LT_TWOEXP] o SPECL [`n`,`2 ** ^WL`]) DA)
    \\ ASM_SIMP_TAC std_ss [MOD_MULT]
    \\ ONCE_REWRITE_TAC [GSYM n2w_mod]
    \\ ASM_SIMP_TAC arith_ss [GSYM MULT,MOD_EQ_0,ZERO_LT_TWOEXP,word_0,dimword_def]);

val WORD_ADD_RINV = store_thm("WORD_ADD_RINV",
  `!w:'a word. w + $- w = 0w`,
  METIS_TAC [WORD_ADD_COMM,WORD_ADD_LINV]);

val WORD_SUB_REFL = store_thm("WORD_SUB_REFL",
  `!w:'a word. w - w = 0w`,
  REWRITE_TAC [word_sub_def,WORD_ADD_RINV]);

val WORD_SUB_ADD2 = store_thm("WORD_SUB_ADD2",
  `!v:'a word w. v + (w - v) = w`,
  REWRITE_TAC [GSYM WORD_ADD_SUB_ASSOC,WORD_ADD_SUB_SYM,
    WORD_SUB_REFL,WORD_ADD_0]);

val WORD_ADD_SUB = store_thm("WORD_ADD_SUB",
  `!v:'a word w. v + w - w = v`,
  REWRITE_TAC [WORD_ADD_SUB_ASSOC,WORD_SUB_REFL,WORD_ADD_0]);

val WORD_SUB_ADD = save_thm("WORD_SUB_ADD",
  REWRITE_RULE [WORD_ADD_SUB_SYM] WORD_ADD_SUB);

val WORD_ADD_EQ_SUB = store_thm("WORD_ADD_EQ_SUB",
  `!v:'a word w x. (v + w = x) = (v = (x - w))`,
  METIS_TAC [WORD_ADD_SUB,WORD_SUB_ADD]);

val WORD_ADD_INV_0_EQ = store_thm("WORD_ADD_INV_0_EQ",
  `!v:'a word w. (v + w = v) = (w = 0w)`,
  REPEAT Cases_word
    \\ ASM_SIMP_TAC std_ss [word_add_n2w,lift_rule ADD_INV_0_EQ_mod]);

val WORD_EQ_ADD_LCANCEL = store_thm("WORD_EQ_ADD_LCANCEL",
  `!v:'a word w x. (v + w = v + x) = (w = x)`,
  REPEAT Cases_word
    \\ ASM_SIMP_TAC std_ss [word_add_n2w,lift_rule EQ_ADD_LCANCEL_mod]);
val _ = export_rewrites ["WORD_EQ_ADD_LCANCEL"]

val WORD_EQ_ADD_RCANCEL = store_thm("WORD_EQ_ADD_RCANCEL",
  `!v:'a word w x. (v + w = x + w) = (v = x)`,
  METIS_TAC [WORD_ADD_COMM,WORD_EQ_ADD_LCANCEL]);
val _ = export_rewrites ["WORD_EQ_ADD_RCANCEL"]

val WORD_NEG = store_thm("WORD_NEG",
  `!w:'a word. $- w = ~w + 1w`,
  REPEAT Cases_word
    \\ ASM_SIMP_TAC (fcp_ss++ARITH_ss) [word_add_n2w,word_2comp_n2w,
         word_1comp_n2w,lift_rule WORD_NEG_mod,dimword_def]);

val WORD_NOT = store_thm("WORD_NOT",
  `!w:'a word. ~w = $- w - 1w`,
  REWRITE_TAC [WORD_NEG,WORD_ADD_SUB]);

val WORD_NEG_0 = store_thm("WORD_NEG_0",
  `$- 0w = 0w`,
   ARITH_WORD_TAC);
val _ = export_rewrites ["WORD_NEG_0"]

val WORD_NEG_ADD = store_thm("WORD_NEG_ADD",
  `!v:'a word w. $- (v + w) = $- v + $- w`,
  REPEAT STRIP_TAC
    \\ `$- v + v + ($-w + w) = 0w`
    by REWRITE_TAC [WORD_ADD_LINV,WORD_ADD_0]
    \\ `$- v + v + ($-w + w) = $- v + $- w + (v + w)`
    by SIMP_TAC std_ss [AC WORD_ADD_ASSOC WORD_ADD_COMM]
    \\ METIS_TAC [GSYM WORD_ADD_LINV,WORD_EQ_ADD_RCANCEL]);

val WORD_NEG_NEG = store_thm("WORD_NEG_NEG",
  `!w:'a word. $- ($- w) = w`,
  STRIP_TAC
    \\ `$- ($- w) + $- w = w + $- w`
    by SIMP_TAC std_ss [WORD_NEG_0,WORD_ADD_0,WORD_ADD_LINV,WORD_ADD_RINV]
    \\ METIS_TAC [WORD_EQ_ADD_RCANCEL]);
val _ = export_rewrites ["WORD_NEG_NEG"]

val WORD_SUB_LNEG = save_thm("WORD_SUB_LNEG",
  (REWRITE_RULE [GSYM word_sub_def] o GSYM) WORD_NEG_ADD);

val WORD_SUB_RNEG = save_thm("WORD_SUB_RNEG",
  (GEN `v` o GEN `w` o REWRITE_RULE [WORD_NEG_NEG] o
   SPECL [`v`,`$- w`]) word_sub_def);

val WORD_SUB_SUB = store_thm("WORD_SUB_SUB",
  `!v:'a word w x. v - (w - x) = v + x - w`,
  SIMP_TAC std_ss [AC WORD_ADD_ASSOC WORD_ADD_COMM,
    word_sub_def,WORD_NEG_ADD,WORD_NEG_NEG]);

val WORD_SUB_SUB2 = save_thm("WORD_SUB_SUB2",
 (GEN `v` o GEN `w` o REWRITE_RULE [WORD_ADD_SUB_SYM,WORD_SUB_REFL,WORD_ADD_0] o
  SPECL [`v`,`v`,`w`]) WORD_SUB_SUB);

val WORD_EQ_SUB_LADD = store_thm("WORD_EQ_SUB_LADD",
  `!v:'a word w x. (v = w - x) = (v + x = w)`,
  METIS_TAC [word_sub_def,WORD_ADD_ASSOC,WORD_ADD_LINV,WORD_ADD_RINV,WORD_ADD_0]);

val WORD_EQ_SUB_RADD = store_thm("WORD_EQ_SUB_RADD",
  `!v:'a word w x. (v - w = x) = (v = x + w)`,
  METIS_TAC [WORD_EQ_SUB_LADD]);

val WORD_EQ_SUB_ZERO = save_thm("WORD_EQ_SUB_ZERO",
  (GEN_ALL o REWRITE_RULE [WORD_ADD_0] o
   SPECL [`v`,`w`,`0w`]) WORD_EQ_SUB_RADD);

val WORD_LCANCEL_SUB = store_thm("WORD_LCANCEL_SUB",
  `!v:'a word w x. (v - w = x - w) = (v = x)`,
  REWRITE_TAC [word_sub_def,WORD_EQ_ADD_RCANCEL]);

val WORD_RCANCEL_SUB = store_thm("WORD_RCANCEL_SUB",
  `!v:'a word w x. (v - w = v - x) = (w = x)`,
  REWRITE_TAC [word_sub_def,WORD_EQ_ADD_LCANCEL]
    \\ METIS_TAC [WORD_NEG_NEG]);

val WORD_SUB_PLUS = store_thm("WORD_SUB_PLUS",
  `!v:'a word w x. v - (w + x) = v - w - x`,
  REWRITE_TAC [word_sub_def,WORD_NEG_ADD,WORD_ADD_ASSOC]);

val WORD_SUB_LZERO = store_thm("WORD_SUB_LZERO",
  `!w:'a word. 0w - w = $- w`,
  REWRITE_TAC [word_sub_def,WORD_ADD_0]);

val WORD_SUB_RZERO = store_thm("WORD_SUB_RZERO",
  `!w:'a word. w - 0w = w`,
  REWRITE_TAC [word_sub_def,WORD_ADD_0,WORD_NEG_0]);

val WORD_ADD_LID_UNIQ = save_thm("WORD_ADD_LID_UNIQ",
  (GEN `v` o GEN `w` o REWRITE_RULE [WORD_SUB_REFL] o
    SPECL [`v`,`w`,`w`]) WORD_ADD_EQ_SUB);

val WORD_ADD_RID_UNIQ = save_thm("WORD_ADD_RID_UNIQ",
  (GEN `v` o GEN `w` o ONCE_REWRITE_RULE [WORD_ADD_COMM] o
   SPECL [`w`,`v`]) WORD_ADD_LID_UNIQ);

val WORD_ADD_SUB2 = save_thm("WORD_ADD_SUB2",
  ONCE_REWRITE_RULE [WORD_ADD_COMM] WORD_ADD_SUB);

val WORD_ADD_SUB3 = save_thm("WORD_ADD_SUB3",
  (GEN_ALL o REWRITE_RULE [WORD_SUB_REFL,WORD_SUB_LZERO] o
   SPECL [`v`,`v`]) WORD_SUB_PLUS);

val WORD_SUB_SUB3 = save_thm("WORD_SUB_SUB3",
  (REWRITE_RULE [WORD_ADD_SUB3] o ONCE_REWRITE_RULE [WORD_ADD_COMM] o
   SPECL [`v`,`w`,`v`] o GSYM) WORD_SUB_PLUS);

val WORD_EQ_NEG = store_thm("WORD_EQ_NEG",
  `!v:'a word w. ($- v = $- w) = (v = w)`,
  REWRITE_TAC [GSYM WORD_SUB_LZERO,WORD_RCANCEL_SUB]);

val WORD_NEG_EQ = save_thm("WORD_NEG_EQ",
  (REWRITE_RULE [WORD_NEG_NEG] o SPECL [`v`,`$- w`]) WORD_EQ_NEG);

val WORD_NEG_EQ_0 = save_thm("WORD_NEG_EQ_0",
  (REWRITE_RULE [WORD_NEG_0] o SPECL [`v`,`0w`]) WORD_EQ_NEG);
val _ = export_rewrites ["WORD_NEG_EQ_0"]

val WORD_SUB = save_thm("WORD_SUB",
  (ONCE_REWRITE_RULE [WORD_ADD_COMM] o GSYM) word_sub_def);

val WORD_SUB_NEG = save_thm("WORD_SUB_NEG",
  (GEN_ALL o REWRITE_RULE [WORD_SUB] o SPEC `$- v`) WORD_SUB_RNEG);

val WORD_NEG_SUB = save_thm("WORD_NEG_SUB",
  (REWRITE_RULE [WORD_SUB_NEG,GSYM word_sub_def] o
   SPECL [`v`,`$- w`] o GSYM) WORD_SUB_LNEG);

val WORD_SUB_TRIANGLE = store_thm("WORD_SUB_TRIANGLE",
  `!v:'a word w x. v - w + (w - x) = v - x`,
  REWRITE_TAC [GSYM WORD_ADD_SUB_SYM,WORD_ADD_SUB_ASSOC,WORD_SUB_SUB3]
    \\ REWRITE_TAC [word_sub_def]);

val WORD_NOT_0 = save_thm("WORD_NOT_0",
  (GEN_ALL o REWRITE_RULE [WORD_NEG_1,WORD_NEG_0,WORD_SUB_LZERO] o
   SPEC `0w`) WORD_NOT);

val WORD_NOT_T = store_thm("WORD_NOT_T",
  `~Tw = 0w`, REWRITE_TAC [GSYM WORD_NOT_0,WORD_NOT_NOT]);

val WORD_NEG_T = store_thm("WORD_NEG_T",
  `$- Tw = 1w`, REWRITE_TAC [GSYM WORD_NEG_1,WORD_NEG_NEG]);

val WORD_MULT_SUC  = store_thm("WORD_MULT_SUC",
  `!v:'a word n. v * n2w (n + 1) = v * n2w n + v`,
  Cases_word \\
    SIMP_TAC arith_ss [word_mul_n2w,word_add_n2w,LEFT_ADD_DISTRIB]);

val WORD_NEG_LMUL = store_thm("WORD_NEG_LMUL",
  `!v:'a word w. $- (v * w) = ($- v) * w`,
  REPEAT Cases_word
    \\ Induct_on `n'` >> REWRITE_TAC [WORD_MULT_CLAUSES,WORD_NEG_0]
    \\ ASM_REWRITE_TAC [WORD_NEG_ADD,ADD1,WORD_MULT_SUC,GSYM word_mul_n2w]);

val WORD_NEG_RMUL = save_thm("WORD_NEG_RMUL",
  (GEN `v` o GEN `w` o ONCE_REWRITE_RULE [WORD_MULT_COMM] o
    SPECL [`w`,`v`]) WORD_NEG_LMUL);

val WORD_NEG_MUL = store_thm("WORD_NEG_MUL",
  `!w. $- w = $- 1w * w`,
  SRW_TAC [] [WORD_NEG_EQ, WORD_NEG_LMUL, WORD_NEG_NEG, WORD_MULT_CLAUSES]);

val WORD_LEFT_SUB_DISTRIB = store_thm("WORD_LEFT_SUB_DISTRIB",
  `!v:'a word w x. v * (w - x) = v * w - v * x`,
  REWRITE_TAC [word_sub_def,WORD_LEFT_ADD_DISTRIB,WORD_NEG_RMUL]);

val WORD_RIGHT_SUB_DISTRIB = save_thm("WORD_RIGHT_SUB_DISTRIB",
  ONCE_REWRITE_RULE [WORD_MULT_COMM] WORD_LEFT_SUB_DISTRIB);

val WORD_LITERAL_MULT = store_thm("WORD_LITERAL_MULT",
  `(!m n. n2w m * $- (n2w n) = $- (n2w (m * n))) /\
   (!m n. $- (n2w m) * $- (n2w n) = n2w (m * n))`,
  REWRITE_TAC
    [GSYM word_mul_n2w, GSYM WORD_NEG_LMUL, GSYM WORD_NEG_RMUL, WORD_NEG_NEG]);

val WORD_LITERAL_ADD = store_thm("WORD_LITERAL_ADD",
  `(!m n. $- (n2w m) + $- (n2w n) = $- (n2w (m + n))) /\
   (!m n. n2w m + $- (n2w n) =
          if n <= m then n2w (m - n) else $- (n2w (n - m)))`,
  REPEAT STRIP_TAC
    >> REWRITE_TAC [GSYM word_sub_def,GSYM word_add_n2w,WORD_NEG_ADD]
    \\ Cases_on `n <= m`
    \\ IMP_RES_TAC (DECIDE ``~(m <= n) ==> n <= m:num``)
    \\ IMP_RES_TAC LESS_EQUAL_ADD
    \\ ASM_REWRITE_TAC [GSYM word_sub_def]
    \\ ONCE_REWRITE_TAC [ADD_COMM]
    \\ REWRITE_TAC [GSYM word_add_n2w,WORD_ADD_SUB,ADD_SUB]
    \\ ONCE_REWRITE_TAC [WORD_ADD_COMM]
    \\ REWRITE_TAC [WORD_SUB_PLUS,WORD_SUB_REFL,WORD_SUB_LZERO]);

val INT_MIN_GT_0 = prove(
  `0 < INT_MIN(:'a)`,
  SRW_TAC [] [INT_MIN_def, ZERO_LT_TWOEXP]);

val WORD_H_WORD_L = store_thm("WORD_H_WORD_L",
  `INT_MAXw = INT_MINw - 1w`,
  SRW_TAC [] [word_H_def, word_L_def, word_sub_def, WORD_LITERAL_ADD,
     INT_MIN_GT_0, INT_MAX_def, DECIDE ``0 < n ==> 1 <= n``]);

val INT_MIN_LT_dimword = prove(
  `INT_MIN (:'a) < dimword (:'a)`,
  SRW_TAC [] [INT_MIN_def, dimword_def, DIMINDEX_GT_0]);

val word_L_MULT = store_thm("word_L_MULT",
  `!n. n2w n * INT_MINw = if EVEN n then 0w else INT_MINw`,
  SRW_TAC [] [word_L_def, word_mul_n2w]
    \\ FULL_SIMP_TAC bool_ss [GSYM ODD_EVEN]
    \\ IMP_RES_TAC EVEN_ODD_EXISTS
    \\ SRW_TAC [] [ADD1, RIGHT_ADD_DISTRIB]
    \\ ONCE_REWRITE_TAC [DECIDE ``a * b * c = a * c * b:num``]
    \\ SRW_TAC [] [SYM dimword_IS_TWICE_INT_MIN]
    \\ SRW_TAC [] [ONCE_REWRITE_RULE [MULT_COMM] MOD_MULT,
                   ONCE_REWRITE_RULE [MULT_COMM] MOD_EQ_0,
                   ZERO_LT_dimword, INT_MIN_LT_dimword]);

(* ------------------------------------------------------------------------- *)
(*  Shifts : theorems                                                        *)
(* ------------------------------------------------------------------------- *)

val WORD_ss = rewrites [word_msb_def,word_lsl_def,word_lsr_def,word_asr_def,
  word_ror_def,word_rol_def,word_rrx_def,word_T,word_or_def,word_lsb_def,
  word_and_def,word_xor_def,n2w_def,DIMINDEX_GT_0,BIT_ZERO,DIMINDEX_LT,
  MOD_PLUS_RIGHT];

val SHIFT_WORD_TAC = RW_TAC (fcp_ss++ARITH_ss++WORD_ss) [];

val ASR_ADD = store_thm("ASR_ADD",
  `!w m n. w >> m >> n = w >> (m + n)`,
  NTAC 2 SHIFT_WORD_TAC
    \\ FULL_SIMP_TAC arith_ss [DECIDE ``!m. m < 1 = (m = 0)``,NOT_LESS_EQUAL]);

val LSR_ADD = store_thm("LSR_ADD",
  `!w m n. w >>> m >>> n = w >>> (m + n)`,
  SHIFT_WORD_TAC \\ Cases_on `i + n < ^WL`
    \\ SHIFT_WORD_TAC);

val ROR_ADD = store_thm("ROR_ADD",
  `!w m n. w #>> m #>> n = w #>> (m + n)`,
  SHIFT_WORD_TAC);

val LSL_ADD = store_thm("LSL_ADD",
  `!w m n. w << m << n = w << (m + n)`,
  SHIFT_WORD_TAC \\ EQ_TAC \\ RW_TAC arith_ss []);

val ASR_LIMIT = store_thm("ASR_LIMIT",
  `!w:'a word n. ^WL <= n ==>
           (w >> n = if word_msb w then Tw else 0w)`,
  SHIFT_WORD_TAC);

val ASR_UINT_MAX = store_thm("ASR_UINT_MAX",
  `!w:'a word n. Tw >> n = Tw`, SHIFT_WORD_TAC);

val LSR_LIMIT = store_thm("LSR_LIMIT",
  `!w:'a word n. ^WL <= n ==> (w >>> n = 0w)`,
  SHIFT_WORD_TAC);

val LSL_LIMIT = store_thm("LSL_LIMIT",
  `!w:'a word n. ^WL <= n ==> (w << n = 0w)`,
  SHIFT_WORD_TAC);

val MOD_TIMES_COMM = ONCE_REWRITE_RULE [ADD_COMM] MOD_TIMES;

val ROR_CYCLE = store_thm("ROR_CYCLE",
  `!w:'a word n. (w #>> (n * ^WL) = w)`,
  SHIFT_WORD_TAC \\ ASM_SIMP_TAC arith_ss [MOD_TIMES_COMM,DIMINDEX_GT_0]);

val ROR_MOD = store_thm("ROR_MOD",
  `!w:'a word n. (w #>> (n MOD ^WL) = w #>> n)`,
  SHIFT_WORD_TAC);

val ROL_MOD = store_thm("ROL_MOD",
  `!w:'a word n. w #<< (n MOD dimindex (:'a)) = w #<< n`,
  SRW_TAC [] [word_rol_def, DIMINDEX_GT_0]);

val SPEC1_RULE = (GEN_ALL o REWRITE_RULE [EXP_1] o
  ONCE_REWRITE_RULE [MULT_COMM] o SPECL [`i`,`x`,`1`]);

val LSL_ONE = store_thm("LSL_ONE",
  `!w:'a word. w << 1 = w + w`,
  STRIP_TAC \\ Cases_on_word `w` \\ REWRITE_TAC [word_add_def,w2n_n2w,dimword_def]
    \\ SHIFT_WORD_TAC \\ Cases_on `1 <= i`
    \\ ASM_SIMP_TAC arith_ss [SPEC1_RULE BIT_SHIFT_THM2,
                              SPEC1_RULE BIT_SHIFT_THM3]
    \\ STRIP_ASSUME_TAC EXISTS_HB \\ POP_ASSUM SUBST_ALL_TAC
    \\ ASM_SIMP_TAC arith_ss [BIT_def,GSYM BITS_ZERO3,BITS_COMP_THM2,MIN_DEF]);

val ROR_UINT_MAX = store_thm("ROR_UINT_MAX",
  `!n. Tw #>> n = Tw`, SHIFT_WORD_TAC);

val ROR_ROL = store_thm("ROR_ROL",
  `!w n. (w #>> n #<< n = w) /\ (w #<< n #>> n = w)`,
  SHIFT_WORD_TAC
    \\ SPECL_THEN [`n`,`^WL`]
         (STRIP_ASSUME_TAC o SIMP_RULE std_ss [DIMINDEX_GT_0]) DA
    >> ASM_SIMP_TAC std_ss [MOD_TIMES,GSYM ADD_ASSOC,DIMINDEX_GT_0,LESS_MOD,
         DECIDE ``!a:num b c. a < c ==> (a + (b + (c - a)) = b + c)``,
         ADD_MODULUS_LEFT]
    \\ ONCE_REWRITE_TAC [ADD_COMM]
    \\ ASM_SIMP_TAC std_ss [MOD_PLUS_RIGHT,MOD_TIMES,DIMINDEX_GT_0,LESS_MOD,
         DECIDE ``!a:num b c d. a < c ==> ((c - a + b + d + a) = c + b + d)``,
         ADD_MODULUS_RIGHT,ONCE_REWRITE_RULE [ADD_COMM] MOD_TIMES,ADD_ASSOC]);

val MOD_MULT_ = SIMP_RULE arith_ss [] MOD_MULT;
val MOD_EQ_0_ = ONCE_REWRITE_RULE [MULT_COMM] MOD_EQ_0;

val lem = prove(
  `!a b. 0 < a /\ 1n < b ==> 2 * a <= a * b`,
  SRW_TAC [] []
    \\ POP_ASSUM (fn th => STRIP_ASSUME_TAC (MATCH_MP LESS_ADD_1 th))
    \\ ASM_SIMP_TAC arith_ss []);

val MOD_SUM_N = prove(
  `!n a b. 0 < n /\ ~(a MOD n + b MOD n = 0)  /\ ((a + b) MOD n = 0) ==>
           (a MOD n + b MOD n = n)`,
  NTAC 3 STRIP_TAC \\ Cases_on `0 < n` \\ ASM_REWRITE_TAC []
    \\ IMP_RES_TAC DA
    \\ POP_ASSUM (fn th => MAP_EVERY (fn v => (STRIP_ASSUME_TAC o SPEC v) th)
         [`a`, `b`, `r + r'`])
    \\ ASM_SIMP_TAC std_ss [MOD_MULT,
         DECIDE ``a * n + r + (b * n + s) = (a + b) * n + (r + s:num)``]
    \\ Cases_on `q'' = 0` >> FULL_SIMP_TAC arith_ss [MOD_MULT_]
    \\ Cases_on `q'' = 1`
    >> FULL_SIMP_TAC arith_ss [MOD_MULT_,
         DECIDE ``n + (r + n * (a + b)) = r + n * (a + b + 1n)``]
    \\ `1 < q''` by DECIDE_TAC \\ IMP_RES_TAC lem
    \\ FULL_SIMP_TAC arith_ss []);

val lem = prove(
  `!a b. 0 < b /\ (a MOD b = 0) ==> ?k. a = k * b`,
  REPEAT STRIP_TAC
    \\ IMP_RES_TAC DA
    \\ POP_ASSUM (SPEC_THEN `a` STRIP_ASSUME_TAC)
    \\ EXISTS_TAC `q`
    \\ FULL_SIMP_TAC arith_ss [MOD_MULT_]);

val MOD_COMPLEMENT = store_thm("MOD_COMPLEMENT",
  `!n q a. 0 < n /\ 0 < q /\ a < q * n ==>
      ((q * n - a) MOD n = (n - a MOD n) MOD n)`,
  SRW_TAC [] [] \\ Cases_on `a MOD n = 0`
    << [
     ASM_SIMP_TAC std_ss [] \\ IMP_RES_TAC lem
       \\ FULL_SIMP_TAC arith_ss [MOD_EQ_0_,
            DECIDE ``n * a - b * n = n * (a - b):num``],
     SRW_TAC [ARITH_ss] [DECIDE ``a < b ==> ((c = b - a) = (c + a = b:num))``]
       \\ MATCH_MP_TAC MOD_SUM_N
       \\ SRW_TAC [ARITH_ss] [MOD_EQ_0_]]);

val ROR_lem =
  METIS_PROVE [ROR_MOD]
  ``!w:'a word a b. (a MOD dimindex(:'a) = b MOD dimindex(:'a)) ==>
      (w #>> a = w #>> b)``;

val ROL_ADD = store_thm("ROL_ADD",
  `!w m n. w #<< m #<< n = w #<< (m + n)`,
  SRW_TAC [] [word_rol_def, ROR_ADD]
    \\ MATCH_MP_TAC ROR_lem
    \\ `m MOD dimindex (:'a) + n MOD dimindex (:'a) < 2 * dimindex(:'a)`
    by SRW_TAC [ARITH_ss]
         [DECIDE ``a < c /\ b < c ==> a + b < 2n * c``, DIMINDEX_GT_0]
    \\ SRW_TAC [ARITH_ss] [DIMINDEX_GT_0, MOD_PLUS, MOD_COMPLEMENT,
         DECIDE ``a < c /\ b < c ==> (c - a + (c - b) = 2n * c - (a + b))``]);

val ZERO_SHIFT = store_thm("ZERO_SHIFT",
  `(!n. 0w:'a word << n  = 0w) /\
   (!n. 0w:'a word >> n  = 0w) /\
   (!n. 0w:'a word >>> n = 0w) /\
   (!n. 0w:'a word #<< n = 0w) /\
   (!n. 0w:'a word #>> n = 0w)`,
  SHIFT_WORD_TAC \\ Cases_on `i + n < ^WL`
    \\ ASM_SIMP_TAC fcp_ss []);

val ROL_ZERO = prove(
  `!w:'a word. w #<< 0 = w`,
  SRW_TAC [ARITH_ss] [DIMINDEX_GT_0, word_rol_def,
    (REWRITE_RULE [MULT_LEFT_1] o SPECL [`w`,`1`]) ROR_CYCLE]);

val SHIFT_ZERO = store_thm("SHIFT_ZERO",
  `(!a. a << 0 = a) /\ (!a. a >> 0 = a) /\
   (!a. a >>> 0 = a) /\ (!a. a #<< 0 = a) /\ (!a. a #>> 0 = a)`,
  REWRITE_TAC [ROL_ZERO] \\ SHIFT_WORD_TAC);

val word_lsl_n2w = store_thm("word_lsl_n2w",
  `!n m. (n2w m):'a word << n =
      if ^HB < n then 0w else n2w (m * 2 ** n)`,
  Induct >> SIMP_TAC arith_ss [SHIFT_ZERO]
    \\ ASM_REWRITE_TAC [ADD1,GSYM LSL_ADD]
    \\ Cases_on `dimindex (:'a) - 1 < n`
    \\ ASM_SIMP_TAC arith_ss [ZERO_SHIFT]
    \\ RW_TAC arith_ss [LSL_ONE,EXP_ADD,word_add_n2w]
    \\ `n = dimindex (:'a) - 1` by DECIDE_TAC
    \\ ONCE_REWRITE_TAC [GSYM n2w_mod]
    \\ ASM_SIMP_TAC (std_ss++numSimps.ARITH_AC_ss) [GSYM EXP,SUB1_SUC,
         MOD_EQ_0,ZERO_MOD,ZERO_LT_TWOEXP,DIMINDEX_GT_0,dimword_def]);

val word_lsr_n2w = store_thm("word_lsr_n2w",
  `!w:'a word n. w >>> n = (^HB -- n) w`,
  SIMP_TAC arith_ss [word_lsr_def,word_bits_def,MIN_IDEM,DIMINDEX_GT_0,
    DECIDE ``0 < m ==> (a <= m - 1 = a < m)``]);

val word_asr_n2w = prove(
  `!n w. w:'a word >> n =
     if word_msb w then
       Tw << (^WL - MIN n ^WL) !! w >>> n
     else
       w >>> n`,
  NTAC 2 STRIP_TAC \\ Cases_on `^WL < n`
    >> RW_TAC arith_ss [MIN_DEF,SHIFT_ZERO,LSR_LIMIT,ASR_LIMIT,WORD_OR_CLAUSES]
    \\ SHIFT_WORD_TAC \\ Cases_on `^WL <= i + n`
    \\ FULL_SIMP_TAC arith_ss [MIN_DEF]);

val lem = (GEN_ALL o REWRITE_RULE [MATCH_MP (DECIDE ``0 < n ==> 1 <= n``)
  (SPEC_ALL ZERO_LT_TWOEXP),MULT_LEFT_1] o SPECL [`1`,`2 ** n`]) LESS_MONO_MULT;

val LSL_UINT_MAX = store_thm("LSL_UINT_MAX",
  `!n. Tw << n = n2w (dimword(:'a) - 2 ** n):'a word`,
  RW_TAC arith_ss [n2w_11,word_T_def,word_lsl_n2w,dimword_def,UINT_MAX_def]
    \\ FULL_SIMP_TAC arith_ss [NOT_LESS,RIGHT_SUB_DISTRIB]
    \\ `n < ^WL` by DECIDE_TAC \\ IMP_RES_TAC TWOEXP_MONO
    \\ `2 ** n * ^dimword_ML - 2 ** n =
          (2 ** n - 1) * ^dimword_ML + (^dimword_ML - 2 ** n)`
    by (`^dimword_ML <= 2 ** n * ^dimword_ML` by ASM_SIMP_TAC arith_ss [lem]
          \\ ASM_SIMP_TAC std_ss [MULT_LEFT_1,RIGHT_SUB_DISTRIB,
               GSYM LESS_EQ_ADD_SUB,LESS_IMP_LESS_OR_EQ,SUB_ADD]
          \\ PROVE_TAC [MULT_COMM])
    \\ ASM_SIMP_TAC std_ss [MOD_TIMES,ZERO_LT_TWOEXP]);

val word_asr_n2w = save_thm("word_asr_n2w",
  REWRITE_RULE [LSL_UINT_MAX] word_asr_n2w);

val BITS_SUM1 =
  (GEN_ALL o REWRITE_RULE [MULT_LEFT_1] o
   INST [`a` |-> `1`] o SPEC_ALL) BITS_SUM;

val lem = (GSYM o SIMP_RULE arith_ss [] o
  SPECL [`p`,`SUC m - n MOD SUC m + p`,
         `SUC m - n MOD SUC m`]) BIT_OF_BITS_THM;

val lem2 = (GSYM o REWRITE_RULE [ADD] o
   SPECL [`p`,`n MOD SUC m - 1`,`0`]) BIT_OF_BITS_THM;

val word_ror_n2w = store_thm("word_ror_n2w",
  `!n a. (n2w a):'a word #>> n =
     let x = n MOD ^WL in
       n2w (BITS ^HB x a + (BITS (x - 1) 0 a) * 2 ** (^WL - x))`,
  SIMP_TAC (bool_ss++boolSimps.LET_ss) [Once (GSYM ROR_MOD)]
    \\ RW_TAC fcp_ss [word_ror_def,n2w_def,DIVISION,DIMINDEX_GT_0]
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC arith_ss [] \\ ONCE_REWRITE_TAC [MULT_COMM]
    \\ Cases_on `i < SUC m - n MOD SUC m`
    << [
      `i + n MOD SUC m < SUC m` by DECIDE_TAC
        \\ PAT_ASSUM `i < y - z` (fn th => (STRIP_ASSUME_TAC o REWRITE_RULE
             [DECIDE ``a + (b + 1) = b + SUC a``]) (MATCH_MP LESS_ADD_1 th))
        \\ ASM_SIMP_TAC std_ss [BITS_SUM2,EXP_ADD,BIT_def,MULT_ASSOC]
        \\ ASM_SIMP_TAC arith_ss [GSYM BIT_def,BIT_OF_BITS_THM],
      RULE_ASSUM_TAC (REWRITE_RULE [NOT_LESS])
        \\ IMP_RES_TAC LESS_EQUAL_ADD
        \\ ASSUME_TAC (SPECL [`m`,`n MOD SUC m`,`a`] BITSLT_THM)
        \\ ASM_SIMP_TAC std_ss [lem,BITS_SUM]
        \\ REWRITE_TAC [GSYM lem]
        \\ ASM_SIMP_TAC std_ss [ONCE_REWRITE_RULE [ADD_COMM] BIT_SHIFT_THM]
        \\ `p < SUC m /\ p <= n MOD SUC m - 1` by DECIDE_TAC
        \\ `SUC m - n MOD SUC m + p + n MOD SUC m = SUC m + p`
        by SIMP_TAC arith_ss [DIVISION,
             DECIDE ``b < a ==> (a - b + c + b = a + c:num)``]
        \\ ASM_SIMP_TAC std_ss [LESS_MOD,prim_recTheory.LESS_0,
             ADD_MODULUS,lem2]]);

val word_rrx_n2w = store_thm("word_rrx_n2w",
  `!c a. word_rrx(c, (n2w a):'a word) =
       (ODD a, (n2w (BITS ^HB 1 a + SBIT c ^HB)):'a word)`,
  SHIFT_WORD_TAC
    \\ RW_TAC arith_ss [GSYM LSB_def,LSB_ODD,SBIT_def,BIT_OF_BITS_THM]
    \\ STRIP_ASSUME_TAC EXISTS_HB \\ FULL_SIMP_TAC arith_ss []
    << [
      METIS_TAC [BITSLT_THM,SUC_SUB1,BITS_SUM1,BIT_def,BIT_B],
      SIMP_TAC arith_ss [BIT_def,BITS_COMP_THM2,MIN_lem,BITS_ZERO],
      `i < m` by DECIDE_TAC
        \\ POP_ASSUM (fn th => (STRIP_ASSUME_TAC o REWRITE_RULE
             [DECIDE ``a + (b + 1) = b + SUC a``]) (MATCH_MP LESS_ADD_1 th))
        \\ ASM_SIMP_TAC std_ss [EXP_ADD,BIT_def,BITS_SUM2,BITS_COMP_THM2]
        \\ SIMP_TAC std_ss [ADD1,ONCE_REWRITE_RULE [ADD_COMM] MIN_lem]]);

val word_ror = store_thm("word_ror",
  `!w:'a word n. w #>> n =
     let x = n MOD dimindex(:'a) in
       (dimindex(:'a) - 1 -- x) w !! (x - 1 -- 0) w << (dimindex (:'a) - x)`,
  SRW_TAC [fcpLib.FCP_ss, boolSimps.LET_ss, ARITH_ss]
       [word_ror_def, word_or_def, word_lsl_def, word_bits_def]
    \\ SPECL_THEN [`n`,`dimindex(:'a)`]
         (STRIP_ASSUME_TAC o SIMP_RULE std_ss [DIMINDEX_GT_0]) DA
    \\ SRW_TAC [] [MOD_TIMES, DIMINDEX_GT_0,
         DECIDE ``a + (b * c + d) = b * c + (a + d:num)``]
    \\ Cases_on `i + r < dimindex (:'a)`
    \\ SRW_TAC [ARITH_ss] []
    \\ SPECL_THEN [`i + r`,`dimindex(:'a)`]
         (STRIP_ASSUME_TAC o SIMP_RULE std_ss [DIMINDEX_GT_0]) DA
    \\ SRW_TAC [] [MOD_TIMES, DIMINDEX_GT_0]
    \\ Cases_on `q = 0` \\ FULL_SIMP_TAC arith_ss []
    \\ Cases_on `q = 1` \\ FULL_SIMP_TAC arith_ss []
    \\ `1 < q` by DECIDE_TAC
    \\ POP_ASSUM (fn th => STRIP_ASSUME_TAC (MATCH_MP LESS_ADD_1 th))
    \\ FULL_SIMP_TAC arith_ss []);

val word_asr = store_thm("word_asr",
  `!w:'a word n. w >> n =
      if word_msb w then
        (dimindex (:'a) - 1 <> dimindex (:'a) - n) UINT_MAXw !! w >>> n
      else
        w >>> n`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
          [word_asr_def, word_lsr_def, word_or_def, n2w_def, word_T,
           word_slice_def]
    \\ Cases_on `i + n < dimindex (:'a)`
    \\ SRW_TAC [ARITH_ss] []);

val WORD_MUL_LSL = store_thm("WORD_MUL_LSL",
  `!a n. a << n = n2w (2 ** n) * a`,
  STRIP_TAC \\ Cases_on_word `a`
    \\ SRW_TAC [ARITH_ss] [word_lsl_n2w, word_mul_n2w, dimword_def]
    \\ `dimindex (:'a) <= n'` by DECIDE_TAC
    \\ IMP_RES_TAC LESS_EQUAL_ADD
    \\ SRW_TAC [ARITH_ss] [EXP_ADD, MOD_EQ_0, ZERO_LT_TWOEXP]);

val WORD_ADD_LSL = store_thm("WORD_ADD_LSL",
  `!n a b. (a + b) << n = a << n + b << n`,
  SRW_TAC [] [WORD_MUL_LSL, WORD_LEFT_ADD_DISTRIB]);

val LSR_BITWISE = store_thm("LSR_BITWISE",
  `(!n v:'a word w:'a word. w >>> n && v >>> n = ((w && v) >>> n)) /\
   (!n v:'a word w:'a word. w >>> n !! v >>> n = ((w !! v) >>> n)) /\
   (!n v:'a word w:'a word. w >>> n ?? v >>> n = ((w ?? v) >>> n))`,
  SHIFT_WORD_TAC \\ Cases_on `i + n < dimindex(:'a)`
    \\ ASM_SIMP_TAC fcp_ss []);

val LSL_BITWISE = store_thm("LSL_BITWISE",
  `(!n v:'a word w:'a word. w << n && v << n = ((w && v) << n)) /\
   (!n v:'a word w:'a word. w << n !! v << n = ((w !! v) << n)) /\
   (!n v:'a word w:'a word. w << n ?? v << n = ((w ?? v) << n))`,
  SHIFT_WORD_TAC << [PROVE_TAC [], PROVE_TAC [], ALL_TAC]
    \\ Cases_on `n <= i` \\ ASM_SIMP_TAC arith_ss []);

val ROR_BITWISE = store_thm("ROR_BITWISE",
  `(!n v:'a word w:'a word. w #>> n && v #>> n = ((w && v) #>> n)) /\
   (!n v:'a word w:'a word. w #>> n !! v #>> n = ((w !! v) #>> n)) /\
   (!n v:'a word w:'a word. w #>> n ?? v #>> n = ((w ?? v) #>> n))`,
  SHIFT_WORD_TAC);

val ROL_BITWISE = store_thm("ROL_BITWISE",
  `(!n v w. w #<< n && v #<< n = (w && v) #<< n) /\
   (!n v w. w #<< n !! v #<< n = (w !! v) #<< n) /\
   !n v w. w #<< n ?? v #<< n = (w ?? v) #<< n`,
  SRW_TAC [] [word_rol_def, ROR_BITWISE]);

val WORD_2COMP_LSL = store_thm("WORD_2COMP_LSL",
  `!n a b. ($- a) << n = $- (a << n)`,
  SRW_TAC [] [WORD_MUL_LSL, WORD_NEG_RMUL]);

val w2w_LSL = store_thm("w2w_LSL",
  `!w:'a word n.
      w2w (w << n):'b word =
      if n < dimindex (:'a) then
        (w2w ((dimindex (:'a) - 1 - n -- 0) w)) << n
      else
        0w`,
  SRW_TAC [] []
    \\ FULL_SIMP_TAC arith_ss [NOT_LESS, LSL_LIMIT, ZERO_SHIFT, w2w_0]
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
         [w2w, word_0, word_lsl_def, word_bits_def]
    \\ Cases_on `i < dimindex (:'a)`
    \\ Cases_on `i - n < dimindex (:'a)`
    \\ FULL_SIMP_TAC (fcp_ss++ARITH_ss)
         [DIMINDEX_GT_0, NOT_LESS, NOT_LESS_EQUAL]);

val WORD_BITS_LSL = store_thm("WORD_BITS_LSL",
  `!h l n w:'a word. h < dimindex(:'a) ==>
      ((h -- l) (w << n) =
         if n <= h then
           (h - n -- l - n) w << (n - l)
         else
           0w)`,
  REPEAT STRIP_TAC \\ Cases_on `h < l`
    \\ RW_TAC arith_ss [LSL_LIMIT, WORD_BITS_ZERO]
    \\ FULL_SIMP_TAC arith_ss
         [NOT_LESS, NOT_LESS_EQUAL, LSL_LIMIT, WORD_BITS_ZERO2, ZERO_SHIFT]
    << [
      Cases_on `n <= l`
        << [`n - l = 0` by DECIDE_TAC,
            FULL_SIMP_TAC std_ss [NOT_LESS_EQUAL] \\ `l - n = 0` by DECIDE_TAC]
        \\ ASM_REWRITE_TAC [SHIFT_ZERO],
      Cases_on `dimindex (:'a) <= n`
        \\ FULL_SIMP_TAC std_ss [NOT_LESS_EQUAL, LSL_LIMIT, WORD_BITS_ZERO2]]
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [word_bits_def, word_lsl_def, word_0]
    \\ Cases_on `i + l <= h /\ i + l <= dimindex (:'a) - 1`
    \\ FULL_SIMP_TAC (fcp_ss++ARITH_ss) []);

val WORD_EXTRACT_LSL = store_thm("WORD_EXTRACT_LSL",
  `!h l n w:'a word. h < dimindex(:'a) ==>
      ((h >< l) (w << n) =
         if n <= h then
           (h - n >< l - n) w << (n - l)
         else
           0w)`,
  SRW_TAC [] [DIMINDEX_GT_0, w2w_LSL, word_extract_def,
              WORD_BITS_LSL, w2w_n2w, BITS_ZERO2]
    \\ SRW_TAC [] [WORD_BITS_COMP_THM]
    << [
      `h - n <= dimindex (:'a) - 1 - (n - l) + (l - n)` by DECIDE_TAC
        \\ ASM_SIMP_TAC std_ss [MIN_FST],
      FULL_SIMP_TAC arith_ss [NOT_LESS]]);

val EXTRACT_JOIN_LSL = store_thm("EXTRACT_JOIN_LSL",
  `!h m l w:'a word.
       l <= m /\ m' <= h /\ (m' = m + 1) /\ (s = m' - l + n) ==>
       ((h >< m') w << s !! (m >< l) w << n =
         ((MIN h (MIN (dimindex(:'b) + l - 1)
            (dimindex(:'a) - 1)) >< l) w << n) :'b word)`,
  SRW_TAC [] [GSYM LSL_ADD, LSL_BITWISE]
    \\ ABBREV_TAC `m' = m + 1`
    \\ ABBREV_TAC `s' = m' - l`
    \\ ASM_SIMP_TAC std_ss [EXTRACT_JOIN]);

val EXTRACT_JOIN_ADD_LSL = store_thm("EXTRACT_JOIN_ADD_LSL",
  `!h m l w:'a word.
       l <= m /\ m' <= h /\ (m' = m + 1) /\ (s = m' - l + n) ==>
       ((h >< m') w << s + (m >< l) w << n =
         ((MIN h (MIN (dimindex(:'b) + l - 1)
            (dimindex(:'a) - 1)) >< l) w << n) :'b word)`,
  SRW_TAC [] [GSYM LSL_ADD, GSYM WORD_ADD_LSL]
    \\ ABBREV_TAC `m' = m + 1`
    \\ ABBREV_TAC `s' = m' - l`
    \\ ASM_SIMP_TAC std_ss [EXTRACT_JOIN_ADD]);

(* ------------------------------------------------------------------------- *)
(*  Orderings : theorems                                                     *)
(* ------------------------------------------------------------------------- *)

val EQUAL_THEN_SUB_ZERO = GEN_ALL (PROVE [WORD_SUB_REFL,WORD_LCANCEL_SUB]
  ``((a - b) = 0w) = (a = b)``);

val order_rule =
   SIMP_RULE (std_ss++boolSimps.LET_ss)
     [nzcv_def,GSYM word_add_n2w,n2w_w2n,GSYM word_sub_def,EQUAL_THEN_SUB_ZERO];

val word_lt = order_rule word_lt_def;
val word_gt = order_rule word_gt_def;
val word_le = order_rule word_le_def;
val word_ge = order_rule word_ge_def;
val word_ls = order_rule word_ls_def;
val word_hi = order_rule word_hi_def;
val word_lo = order_rule word_lo_def;
val word_hs = order_rule word_hs_def;

val SPEC_LESS_EXP_SUC_MONO = prove(
  `2 ** ^HB < 2 ** dimindex (:'a)`,
  SRW_TAC [][DIMINDEX_GT_0])

val SPLIT_2_EXP_WL = prove(
  `^dimword_ML = ^INT_MIN_ML + ^INT_MIN_ML`,
  STRIP_ASSUME_TAC EXISTS_HB
    \\ ASM_SIMP_TAC arith_ss [EXP]);

val WORD_NEG_L = store_thm("WORD_NEG_L",
  `$- word_L = word_L`,
  SRW_TAC [][word_2comp_n2w, word_L_def, LESS_MOD, DIMINDEX_GT_0, dimword_def,
             INT_MIN_def, SUB_RIGHT_EQ, SPLIT_2_EXP_WL])

val word_L_MULT_NEG = store_thm("word_L_MULT_NEG",
  `!n. $- (n2w n) * INT_MINw = if EVEN n then 0w else INT_MINw`,
  ONCE_REWRITE_TAC [WORD_NEG_MUL]
    \\ SRW_TAC [] [GSYM WORD_MULT_ASSOC, word_L_MULT, WORD_MULT_CLAUSES]
    \\ SRW_TAC [] [GSYM WORD_NEG_MUL, WORD_NEG_L]);

val word_L2_MULT = store_thm("word_L2_MULT",
  `(INT_MINw2 * INT_MINw2 = INT_MINw2) /\
   (INT_MINw * INT_MINw2 = INT_MINw2) /\
   (!n. n2w n * INT_MINw2 = if EVEN n then 0w else INT_MINw2) /\
   (!n. $- (n2w n) * INT_MINw2 = if EVEN n then 0w else INT_MINw2)`,
  RW_TAC std_ss ([word_L2_def, word_L_def, WORD_MULT_CLAUSES] @
       map (ONCE_REWRITE_RULE [word_L_def])
         [word_L_MULT, word_L_MULT_NEG]));

(* ------------------------------------------------------------------------- *)

val BITS_COMP_MSB = (SIMP_RULE arith_ss [] o
  SPECL [`m`,`0`,`m - 1`,`0`]) BITS_COMP_THM;

val SLICE_COMP_MSB = prove(
  `!b n. ~(b = 0) ==> (SLICE b b n + SLICE (b - 1) 0 n = SLICE b 0 n)`,
   REPEAT STRIP_TAC
     \\ POP_ASSUM (fn th => REWRITE_TAC [(SIMP_RULE arith_ss [SUB_SUC1,th] o
          SPECL [`b`,`b - 1`,`0`,`n`]) SLICE_COMP_THM]));

val MSB_THM1 = prove(
  `!a:'a word. ~(^HB = 0) /\ word_msb a ==>
        (w2n a = ^INT_MIN_ML + BITS (^HB - 1) 0 (w2n a))`,
  Cases_word \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ RW_TAC arith_ss [word_msb_n2w,w2n_n2w,GSYM BITS_ZERO3,BITS_COMP_MSB,
                        dimword_def]
    \\ IMP_RES_TAC BIT_SLICE_THM2 \\ POP_ASSUM (SUBST1_TAC o SYM)
    \\ ASM_SIMP_TAC arith_ss [SLICE_COMP_MSB,GSYM SLICE_ZERO_THM]);

val MSB_THM2 = prove(
  `!a:'a word. ~(^HB = 0) /\ word_msb a ==>
        (w2n ($- a) = ^INT_MIN_ML - BITS (^HB - 1) 0 (w2n a))`,
  Cases_word \\ REPEAT STRIP_TAC \\ IMP_RES_TAC MSB_THM1
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC arith_ss [word_msb_n2w,word_2comp_n2w,w2n_n2w,
         BITS_COMP_MSB,GSYM BITS_ZERO3, dimword_def]
    \\ ASM_SIMP_TAC arith_ss [BITS_ZERO3,GSYM ADD1,ADD_MODULUS,MOD_MOD,
         ZERO_LT_TWOEXP,SUB_SUC1]
    \\ REWRITE_TAC [EXP,TIMES2,SUB_PLUS,ADD_SUB]
    \\ `2 ** m - n MOD 2 ** m < 2 ** SUC m` by METIS_TAC
         [DECIDE ``a - b <= a /\ a < SUC a``,TWOEXP_MONO,LESS_EQ_LESS_TRANS]
    \\ ASM_SIMP_TAC arith_ss [GSYM EXP,LESS_MOD]);

val MSB_THM3 = prove(
  `!a:'a word. ~(^HB = 0) /\ ~word_msb a ==>
        (w2n a = BITS (^HB - 1) 0 (w2n a))`,
  Cases_word \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ RW_TAC arith_ss [word_msb_n2w,w2n_n2w,GSYM BITS_ZERO3,BITS_COMP_MSB,
                        dimword_def]
    \\ `~(m = 0)` by DECIDE_TAC
    \\ MAP_EVERY IMP_RES_TAC [BIT_SLICE_THM3,SLICE_COMP_MSB]
    \\ POP_ASSUM (SPEC_THEN `n` ASSUME_TAC)
    \\ PAT_ASSUM `SLICE m m n = 0` (fn th =>
         FULL_SIMP_TAC arith_ss [th,GSYM SLICE_ZERO_THM]));

val MSB_THM4 = prove(
  `!a:'a word. ~(^HB = 0) /\ ~(a = 0w) /\ ~word_msb a ==>
       (w2n ($- a) = ^dimword_ML - BITS (^HB - 1) 0 (w2n a)) /\
       ~(BITS (^HB - 1) 0 (w2n a) = 0)`,
  Cases_word \\ REPEAT STRIP_TAC \\ IMP_RES_TAC MSB_THM3
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC arith_ss [word_msb_n2w,word_2comp_n2w,w2n_n2w,n2w_11,
         GSYM BITS_ZERO3,BITS_ZERO2,BITS_COMP_MSB,dimword_def]
    \\ FULL_SIMP_TAC arith_ss [BITS_COMP_THM2,MIN_DEF]
    \\ `2 ** SUC m - BITS (m - 1) 0 n < 2 ** SUC m`
    by ASM_SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
    \\ ASM_SIMP_TAC bool_ss [BITS_ZEROL]);

val HB_0_MSB = prove(
  `!a:'a word. (^HB = 0) /\ word_msb a ==> (a = 1w)`,
  Cases_word \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ RW_TAC bool_ss [word_msb_n2w,w2n_n2w,n2w_11,BIT_def,SUC_SUB1,dimword_def]
    \\ FULL_SIMP_TAC arith_ss [BITS_ZERO3]);

val HB_0_NOT_MSB = prove(
  `!a:'a word. (^HB = 0) /\ ~word_msb a ==> (a = 0w)`,
  Cases_word \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ RW_TAC fcp_ss [word_msb_n2w,n2w_11,ZERO_MOD,ZERO_LT_TWOEXP,
         GSYM BITS_ZERO3,dimword_def]
    \\ METIS_TAC [DECIDE ``SUC m <= 1 = (m = 0)``,BIT_def,NOT_BITS2]);

val DIMINDEX_1 = prove(
  `(^WL - 1 = 0) ==> (^WL = 1)`,
  STRIP_ASSUME_TAC EXISTS_HB \\ ASM_SIMP_TAC arith_ss []);

val MSB_THM1b = prove(
  `!a:'a word. (^HB = 0) /\ word_msb a ==> (w2n a = 1)`,
  METIS_TAC [HB_0_MSB,DIMINDEX_1,EXP_1,LESS_MOD,DECIDE ``1 < 2``,w2n_n2w,
             dimword_def]);

val MSB_THM2b = prove(
  `!a:'a word. (^HB = 0) /\ word_msb a ==> (w2n (word_2comp a) = 1)`,
  REPEAT STRIP_TAC \\ MAP_EVERY IMP_RES_TAC [HB_0_MSB,DIMINDEX_1]
    \\ ASM_SIMP_TAC arith_ss [w2n_n2w,word_2comp_n2w,dimword_def]);

val MSB_THM3b = prove(
  `!a:'a word. (^HB = 0) /\ ~word_msb a ==> (w2n a = 0)`,
  REPEAT STRIP_TAC \\ MAP_EVERY IMP_RES_TAC [HB_0_NOT_MSB,DIMINDEX_1]
    \\ ASM_SIMP_TAC arith_ss [w2n_n2w,dimword_def]);

val MSB_THM4b = prove(
  `!a:'a word. (^HB = 0) /\ ~word_msb a ==> (w2n (word_2comp a) = 0)`,
  REPEAT STRIP_TAC \\ MAP_EVERY IMP_RES_TAC [HB_0_NOT_MSB,DIMINDEX_1]
    \\ ASM_SIMP_TAC arith_ss [w2n_n2w,WORD_NEG_0,dimword_def]);

(* ------------------------------------------------------------------------- *)

val w2n_mod = PROVE [n2w_w2n,n2w_mod,dimword_def]
   ``(w2n (a:'a word) = n) ==> (a = n2w (n MOD ^dimword_ML))``;

val BITS_MSB_LT = (GEN_ALL o SIMP_RULE arith_ss [SUB_SUC1] o
  DISCH `~(b = 0)` o SPECL [`b - 1`,`0`,`a`]) BITSLT_THM;

val SLICE_MSB_LT = REWRITE_RULE [GSYM SLICE_ZERO_THM] BITS_MSB_LT;

val BITS_MSB_LTEQ = prove(
  `!b a. ~(b = 0) ==> BITS (b - 1) 0 a <= 2 ** b`,
  PROVE_TAC [LESS_IMP_LESS_OR_EQ,BITS_MSB_LT]);

val TWO_COMP_POS = prove(
  `!a:'a word. ~word_msb a ==>
          (if a = 0w then ~word_msb ($- a) else word_msb ($- a))`,
  Cases_word
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ RW_TAC bool_ss [WORD_NEG_0]
    \\ Cases_on `^HB = 0` >> PROVE_TAC [HB_0_NOT_MSB]
    \\ `~(m = 0)` by DECIDE_TAC
    \\ MAP_EVERY IMP_RES_TAC [MSB_THM4,w2n_mod]
    \\ PAT_ASSUM `dimindex(:'a) = SUC m` (fn t =>
         FULL_SIMP_TAC arith_ss [word_msb_n2w,BITS_COMP_THM2,MIN_DEF,BIT_def,t])
    \\ `2 ** SUC m - BITS (m - 1) 0 (w2n ((n2w n):'a word)) < 2 ** SUC m /\
        2 ** m - BITS (m - 1) 0 (w2n ((n2w n):'a word)) < 2 ** m`
    by ASM_SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
    \\ ASM_SIMP_TAC std_ss [LESS_MOD] \\ IMP_RES_TAC BITS_MSB_LTEQ
    \\ ASM_SIMP_TAC bool_ss [SPECL [`m`,`m`] BITS_THM,SUC_SUB,EXP_1,EXP,
         TIMES2,LESS_EQ_ADD_SUB,DIV_MULT_1] \\ numLib.REDUCE_TAC);

val TWO_COMP_NEG_lem = prove(
  `!n. ~(^HB = 0) /\ ~((n2w n):'a word = word_L) /\
       word_msb ((n2w n):'a word) ==>
       ~(BITS (^WL - 2) 0 (w2n ((n2w n):'a word)) = 0)`,
  REPEAT STRIP_TAC \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC arith_ss [BITS_COMP_THM2,MIN_DEF,GSYM BITS_ZERO3,
         word_msb_n2w,w2n_n2w,dimword_def]
    \\ IMP_RES_TAC BIT_SLICE_THM2
    \\ RULE_ASSUM_TAC (REWRITE_RULE [GSYM SLICE_ZERO_THM])
    \\ `~(m = 0)` by DECIDE_TAC \\ IMP_RES_TAC SLICE_COMP_MSB
    \\ POP_ASSUM (SPEC_THEN `n` ASSUME_TAC)
    \\ FULL_SIMP_TAC arith_ss [word_L_def,n2w_11,LESS_MOD,
         SUC_SUB1,SUC_SUB2,TWOEXP_MONO,dimword_def,INT_MIN_def]
    \\ FULL_SIMP_TAC bool_ss [GSYM BITS_ZERO3,GSYM SLICE_ZERO_THM]
    \\ PROVE_TAC [ADD_0]);

val TWO_COMP_NEG = store_thm("TWO_COMP_NEG",
  `!a:'a word. word_msb a ==>
       if (^HB = 0) \/ (a = word_L) then
         word_msb (word_2comp a)
       else
        ~word_msb (word_2comp a)`,
  RW_TAC bool_ss [] << [
    IMP_RES_TAC HB_0_MSB
      \\ ASM_SIMP_TAC arith_ss [word_msb_n2w,word_T_def,WORD_NEG_1,
           DIMINDEX_GT_0,ONE_COMP_0_THM,UINT_MAX_def,dimword_def],
    ASM_REWRITE_TAC [WORD_NEG_L],
    FULL_SIMP_TAC bool_ss [] \\ Cases_on_word `a`
      \\ MAP_EVERY IMP_RES_TAC [MSB_THM2,w2n_mod,TWO_COMP_NEG_lem]
      \\ STRIP_ASSUME_TAC EXISTS_HB \\ `~(m = 0)` by DECIDE_TAC
      \\ FULL_SIMP_TAC arith_ss [BITS_COMP_THM2,MIN_DEF,BIT_def,
           word_msb_n2w,w2n_n2w,GSYM BITS_ZERO3,SUC_SUB2,dimword_def]
      \\ `2 ** m - BITS (m - 1) 0 n < 2 ** m`
      by ASM_SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
      \\ ASM_SIMP_TAC arith_ss [BITS_THM,SUC_SUB,EXP_1,LESS_DIV_EQ_ZERO]]);

val TWO_COMP_POS_NEG = store_thm("TWO_COMP_POS_NEG",
  `!a:'a word. ~((^HB = 0) \/ (a = 0w) \/ (a = word_L)) ==>
     (~word_msb a = word_msb (word_2comp a))`,
  REPEAT STRIP_TAC \\ EQ_TAC \\ REPEAT STRIP_TAC
    >> METIS_TAC [TWO_COMP_POS]
    \\ METIS_TAC [WORD_NEG_L,WORD_NEG_EQ,WORD_NEG_NEG,TWO_COMP_NEG]);

val TWO_COMP_NEG_POS = METIS_PROVE [TWO_COMP_POS_NEG]
  ``!a:'a word. ~((^HB = 0) \/ (a = 0w) \/ (a = word_L)) ==>
     (word_msb a = ~word_msb (word_2comp a))``;

val WORD_0_POS = store_thm("WORD_0_POS",
  `~word_msb 0w`, REWRITE_TAC [word_msb_n2w,BIT_ZERO]);

val TWO_COMP_POS = save_thm("TWO_COMP_POS",
  METIS_PROVE [TWO_COMP_POS, WORD_NEG_0, WORD_0_POS]
  ``~word_msb a ==> (a = 0w) \/ word_msb ($- a)``);

val WORD_H_POS = store_thm("WORD_H_POS",
  `~word_msb word_H`,
  `^INT_MIN_ML - 1 < ^INT_MIN_ML` by ASM_SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
     \\ ASM_SIMP_TAC bool_ss [word_H_def,word_msb_n2w,BIT_def,BITS_THM,
          LESS_DIV_EQ_ZERO,ZERO_MOD,ZERO_LT_TWOEXP,INT_MIN_def,INT_MAX_def]
     \\ DECIDE_TAC);

val WORD_L_NEG = store_thm("WORD_L_NEG",
  `word_msb word_L`,
   REWRITE_TAC [word_L_def,word_msb_n2w,BIT_ZERO,BIT_B,INT_MIN_def]);

(* ------------------------------------------------------------------------- *)

val NOT_EQUAL_THEN_NOT =
  PROVE [EQUAL_THEN_SUB_ZERO] ``!a b. ~(a = b) = ~(b - a = 0w)``;

val SUB_EQUAL_WORD_L_INT_MIN = prove(
  `!a:'a word b:'a word. ~(^HB = 0) /\ (a - b = word_L) ==>
      ~(word_msb a = word_msb b)`,
  RW_TAC bool_ss [WORD_EQ_SUB_RADD] \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ `~(m = 0)` by DECIDE_TAC \\ Cases_on_word `b`
    \\ ASM_REWRITE_TAC [word_msb_n2w,word_L_def,SUC_SUB1,INT_MIN_def]
    \\ SUBST1_TAC ((SYM o SPEC `n`) n2w_mod)
    \\ ASM_REWRITE_TAC [word_msb_n2w,word_add_n2w,SUC_SUB1,
         GSYM BITS_ZERO3,GSYM SLICE_ZERO_THM,dimword_def]
    \\ `SLICE m 0 n = SLICE m m n + SLICE (m - 1) 0 n`
    by METIS_TAC [SLICE_COMP_MSB,SUC_SUB2]
    \\ Cases_on `BIT m n`
    << [IMP_RES_TAC BIT_SLICE_THM2,IMP_RES_TAC BIT_SLICE_THM3]
    \\ ASM_SIMP_TAC arith_ss [BIT_def,BITS_THM,SUC_SUB,EXP_1,SLICE_MSB_LT,
         DIV_MULT,DIV_MULT_1]);

val LEM1_TAC =
  REPEAT STRIP_TAC
    \\ MAP_EVERY Cases_on [`word_msb a`,`word_msb b`,`a = b`]
    \\ FULL_SIMP_TAC bool_ss [word_lt,word_gt,word_le,word_ge,
         WORD_SUB_REFL,WORD_0_POS,DECIDE (Term `~(a = ~a)`)]
    \\ GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV)
         empty_rewrites [GSYM WORD_NEG_SUB]
    \\ IMP_RES_TAC NOT_EQUAL_THEN_NOT \\ Cases_on `b - a = word_L`
    \\ PROVE_TAC [SUB_EQUAL_WORD_L_INT_MIN,TWO_COMP_POS_NEG];

val LEM2_TAC =
  REPEAT STRIP_TAC \\ MAP_EVERY Cases_on [`word_msb a`,`word_msb b`]
    \\ MAP_EVERY IMP_RES_TAC [MSB_THM1b,MSB_THM2b,MSB_THM3b,MSB_THM4b]
    \\ ASM_SIMP_TAC arith_ss [word_lt,word_gt,word_le,word_ge,word_sub_def,
         word_add_def,word_add_n2w,word_msb_n2w,n2w_11,BITS_ZERO2,BIT_def,
         dimword_def]
    \\ ASM_SIMP_TAC arith_ss [BITS_ZERO3]
    \\ PROVE_TAC [w2n_11];

val WORD_GREATER = store_thm("WORD_GREATER",
  `!a:'a word b. a > b = b < a`,
  Cases_on `^HB = 0` << [LEM2_TAC,LEM1_TAC]);

val WORD_GREATER_EQ = store_thm("WORD_GREATER_EQ",
  `!a:'a word b. a >= b = b <= a`,
  Cases_on `^HB = 0` << [LEM2_TAC,LEM1_TAC]);

val WORD_NOT_LESS = store_thm("WORD_NOT_LESS",
  `!a:'a word b. ~(a < b) = b <= a`,
  Cases_on `^HB = 0` << [LEM2_TAC,LEM1_TAC]);

(* ------------------------------------------------------------------------- *)

val LESS_EQ_ADD2 = DECIDE (Term `!a:num b c. a + b <= a + c ==> b <= c`);
val LESS_ADD2 = DECIDE (Term `!a:num b c. a + b < a + c ==> b < c`);
val LESS_EQ_ADD_SUB2 =
   DECIDE (Term `!m:num n p. p <= n ==> (m + p - n = m - (n - p))`);
val SUB_SUC1 = DECIDE ``!m. ~(m = 0) ==> (SUC (m - 1) = m)``;

val start_tac =
  REWRITE_TAC [word_sub_def,word_add_def] \\ RW_TAC bool_ss [word_msb_n2w]
    \\ POP_ASSUM MP_TAC \\ Cases_on `w2n a < w2n b`
    \\ ASM_REWRITE_TAC [] \\ IMP_RES_TAC MSB_THM1
    \\ `w2n ($- b) = ^INT_MIN_ML - BITS (^HB - 1) 0 (w2n b)`
          by IMP_RES_TAC MSB_THM2
    \\ ABBREV_TAC `x = BITS (^HB - 1) 0 (w2n a)`
    \\ ABBREV_TAC `y = BITS (^HB - 1) 0 (w2n b)`
    \\ FULL_SIMP_TAC bool_ss [NOT_LESS,GSYM LESS_EQ_ADD_SUB,BITS_MSB_LT,
         DECIDE (Term `!a b. a + b + a = 2 * a + b`)];

val WORD_LT_lem = prove(
  `!a:'a word b. ~(^HB = 0) /\ word_msb a /\
         word_msb b /\ word_msb (a - b) ==> w2n a < w2n b`,
  start_tac \\ IMP_RES_TAC LESS_EQ_ADD2
    \\ ASM_SIMP_TAC bool_ss [Abbr`x`,Abbr`y`,LESS_EQ_ADD_SUB2,BIT_def,
         BITS_THM,SUC_SUB,EXP_1,DIV_1,SUB_0,CONJUNCT1 EXP,LESS_EQ_ADD_SUB,
         NOT_MOD2_LEM2,SUB_SUC1]
    \\ SIMP_TAC arith_ss [MOD_2EXP_LT,SUB_LEFT_ADD,
         DECIDE ``a < b ==> ~(b <= a:num)``]
    \\ PAT_ASSUM `~(x = 0)` ASSUME_TAC \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC bool_ss [SUC_SUB1,BITS_ZERO3,LESS_EQ_ADD_SUB,SUB_SUC1,
         DECIDE ``a < c /\ b < c ==> (a - b) < c:num``,MOD_2EXP_LT,DIV_MULT,
         DIVMOD_ID,DECIDE ``0 < 2``]);

val WORD_LT_lem2 = prove(
  `!a:'a word b. ~(^HB = 0) /\ word_msb a /\ word_msb b /\
         ~word_msb (a - b) ==> ~(w2n a < w2n b)`,
  start_tac
    \\ ONCE_REWRITE_TAC [DECIDE (Term `!a b c. (a:num) + b + c = a + c + b`)]
    \\ PAT_ASSUM `x + y < x + z` (ASSUME_TAC o (MATCH_MP LESS_ADD2))
    \\ IMP_RES_TAC LESS_ADD_1
    \\ `y < ^INT_MIN_ML` by METIS_TAC [BITS_MSB_LT]
    \\ `p + 1 <= ^INT_MIN_ML` by DECIDE_TAC
    \\ ASM_SIMP_TAC arith_ss [SUB_LEFT_ADD] \\ IMP_RES_TAC LESS_EQUAL_ADD
    \\ ASM_SIMP_TAC std_ss [TIMES2,DECIDE ``x + (y + p) = x + p + y:num``,
         DECIDE ``a + b + c - (c + b) = a:num``]
    \\ `p' < p + 1 + p'` by DECIDE_TAC
    \\ ASM_SIMP_TAC bool_ss [BIT_def,BITS_THM,SUC_SUB,EXP_1,DIV_MULT_1]
    \\ numLib.REDUCE_TAC);

val w2n_0 =
  SIMP_CONV arith_ss [w2n_n2w,ZERO_MOD,ZERO_LT_TWOEXP,dimword_def] ``w2n 0w``;

val start_tac = REWRITE_TAC [word_sub_def,word_add_def]
    \\ NTAC 2 STRIP_TAC
    \\ Cases_on `b = 0w`
    >> (ASM_REWRITE_TAC [WORD_NEG_0,w2n_0,ADD_0,n2w_w2n]
          \\ PROVE_TAC [prim_recTheory.NOT_LESS_0])
    \\ RW_TAC bool_ss [word_msb_n2w]
    \\ POP_ASSUM MP_TAC
    \\ Cases_on `w2n a < w2n b` \\ ASM_REWRITE_TAC []
    \\ IMP_RES_TAC MSB_THM3
    \\ `w2n ($- b) = ^dimword_ML - BITS (^HB - 1) 0 (w2n b)`
          by IMP_RES_TAC MSB_THM4
    \\ ABBREV_TAC `x = BITS (^HB - 1) 0 (w2n a)`
    \\ ABBREV_TAC `y = BITS (^HB - 1) 0 (w2n b)`
    \\ `y <= ^INT_MIN_ML` by METIS_TAC [BITS_MSB_LTEQ]
    \\ `y <= ^dimword_ML` by METIS_TAC [SPEC_LESS_EXP_SUC_MONO,
                                    LESS_IMP_LESS_OR_EQ,LESS_EQ_TRANS]
    \\ FULL_SIMP_TAC bool_ss [NOT_LESS,GSYM LESS_EQ_ADD_SUB]
    \\ ONCE_REWRITE_TAC [ADD_COMM];

val WORD_LT_lem3 = prove(
  `!a:'a word b. ~(^HB = 0) /\ ~word_msb a /\ ~word_msb b /\
         word_msb (a - b) ==> w2n a < w2n b`,
  start_tac \\ `x < ^INT_MIN_ML` by METIS_TAC [BITS_MSB_LT]
    \\ `x - y < ^INT_MIN_ML` by DECIDE_TAC
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC bool_ss [BIT_def,BITS_THM,SUC_SUB,EXP_1,
         LESS_EQ_ADD_SUB,EXP,DIV_MULT,SUC_SUB1]
    \\ numLib.REDUCE_TAC);

val WORD_LT_lem4 = prove(
  `!a:'a word b. ~(^HB = 0) /\ ~word_msb a /\ ~word_msb b /\
        ~word_msb (a - b) ==> ~(w2n a < w2n b)`,
  start_tac
    \\ `y <= ^INT_MIN_ML + x` by DECIDE_TAC
    \\ ASM_SIMP_TAC bool_ss [SPLIT_2_EXP_WL,GSYM ADD_ASSOC,LESS_EQ_ADD_SUB]
    \\ IMP_RES_TAC LESS_IMP_LESS_OR_EQ
    \\ `^INT_MIN_ML - (y - x) < ^INT_MIN_ML` by DECIDE_TAC
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC bool_ss [LESS_EQ_ADD_SUB2,DIV_MULT_1,BIT_def,
         BITS_THM,SUC_SUB,EXP_1]
    \\ numLib.REDUCE_TAC);

val WORD_LT = store_thm("WORD_LT",
  `!a b. word_lt a b = (word_msb a = word_msb b) /\ w2n a < w2n b \/
                        word_msb a /\ ~word_msb b`,
  Tactical.REVERSE (Cases_on `^HB = 0`) \\ REPEAT STRIP_TAC
    >> METIS_TAC [word_lt,WORD_LT_lem,WORD_LT_lem2,WORD_LT_lem3,WORD_LT_lem4]
    \\ MAP_EVERY Cases_on [`word_msb a`,`word_msb b`,
         `word_msb (n2w (w2n a + w2n ($- b)):'a word)`]
    \\ ASM_REWRITE_TAC [word_lt] \\ POP_ASSUM MP_TAC
    \\ Cases_on `w2n a < w2n b`
    \\ ASM_REWRITE_TAC [word_msb_n2w,word_sub_def,word_add_def]
    \\ MAP_EVERY IMP_RES_TAC [MSB_THM1b,MSB_THM2b,MSB_THM3b,MSB_THM4b]
    \\ ASM_SIMP_TAC arith_ss [BIT_def,BITS_THM]);

val WORD_GT = save_thm("WORD_GT",
  (GEN `a` o GEN `b` o REWRITE_CONV [WORD_GREATER,WORD_LT,GSYM GREATER_DEF])
  ``a:'a word > b``);

val WORD_LE = store_thm("WORD_LE",
  `!a:'a word b. a <= b = (word_msb a = word_msb b) /\ (w2n a <= w2n b) \/
                             word_msb a /\ ~word_msb b`,
  SIMP_TAC bool_ss [WORD_LT,GSYM WORD_NOT_LESS,NOT_LESS] \\ DECIDE_TAC);

val WORD_GE = save_thm("WORD_GE",
  (GEN `a` o GEN `b` o REWRITE_CONV [WORD_GREATER_EQ,WORD_LE,GSYM GREATER_EQ])
  ``a:'a word >= b``);

val w2n_2comp = prove(
  `!a:'a word. w2n ($- a) = if a = 0w then 0 else ^dimword_ML - w2n a`,
  RW_TAC bool_ss [WORD_NEG_0,w2n_0] \\ Cases_on_word `a`
    \\ FULL_SIMP_TAC bool_ss [GSYM w2n_11,w2n_0,w2n_n2w,word_2comp_n2w,dimword_def]
    \\ `^dimword_ML - n MOD ^dimword_ML < ^dimword_ML`
          by ASM_SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
    \\ ASM_SIMP_TAC bool_ss [LESS_MOD]);

val WORD_LO = store_thm("WORD_LO",
  `!a b. a <+ b = w2n a < w2n b`,
  RW_TAC bool_ss [word_lo] \\ Cases_on `b = 0w`
    \\ ASM_SIMP_TAC arith_ss [w2n_2comp,w2n_0,GSYM LESS_EQ_ADD_SUB,
         REWRITE_RULE [dimword_def]
                      (MATCH_MP LESS_IMP_LESS_OR_EQ (SPEC `b` w2n_lt))]
    \\ Cases_on `a = b` >> ASM_SIMP_TAC arith_ss [BIT_B]
    \\ Cases_on `w2n a < w2n b` \\ ASM_REWRITE_TAC []
    \\ ONCE_REWRITE_TAC [ADD_COMM]
    \\ RULE_ASSUM_TAC (REWRITE_RULE [GSYM w2n_11,w2n_0,w2n_n2w]) << [
      IMP_RES_TAC LESS_IMP_LESS_OR_EQ
        \\ `~(w2n b - w2n a = 0)` by DECIDE_TAC
        \\ POP_ASSUM (fn th => `^dimword_ML - (w2n b - w2n a) < ^dimword_ML`
                                   by SIMP_TAC arith_ss [th,ZERO_LT_TWOEXP])
        \\ ASM_SIMP_TAC arith_ss [GSYM SUB_SUB,BIT_def,BITS_THM,SUC_SUB,
             EXP_1,LESS_DIV_EQ_ZERO],
      RULE_ASSUM_TAC (REWRITE_RULE [NOT_LESS])
        \\ ASSUME_TAC (REWRITE_RULE [dimword_def] (SPEC `a` w2n_lt))
        \\ `w2n a - w2n b < ^dimword_ML`
        by ASM_SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
        \\ ASM_SIMP_TAC bool_ss [LESS_EQ_ADD_SUB,BIT_def,BITS_THM,SUC_SUB,
             EXP_1,DIV_MULT_1]
        \\ numLib.REDUCE_TAC]);

val WORD_LS_LO_EQ  = PROVE [word_ls,word_lo] ``a <=+ b = a <+ b \/ (a = b)``;
val WORD_HI_NOT_LS = PROVE [word_ls,word_hi] ``a >+ b = ~(a <=+ b)``;
val WORD_HS_NOT_LO = PROVE [word_hs,word_lo] ``a >=+ b = ~(a <+ b)``;

val WORD_LS = store_thm("WORD_LS",
  `!a b. a <=+ b = w2n a <= w2n b`,
  PROVE_TAC [w2n_11,WORD_LO,WORD_LS_LO_EQ,LESS_OR_EQ]);

val WORD_HI = store_thm("WORD_HI",
  `!a b. a >+ b = w2n a > w2n b`,
  REWRITE_TAC [WORD_HI_NOT_LS,WORD_LS,GSYM NOT_GREATER]);

val WORD_HS = store_thm("WORD_HS",
  `!a b. a >=+ b = w2n a >= w2n b`,
  REWRITE_TAC [WORD_HS_NOT_LO,WORD_LO,DECIDE ``~(a < b) = a >= b:num``]);

(* ------------------------------------------------------------------------- *)

val WORD_NOT_LESS_EQUAL = store_thm("WORD_NOT_LESS_EQUAL",
  `!a:'a word b. ~(a <= b) = b < a`, PROVE_TAC [WORD_NOT_LESS]);

val WORD_LESS_OR_EQ = store_thm("WORD_LESS_OR_EQ",
  `!a:'a word b. a <= b = a < b \/ (a = b)`, LEM1_TAC);

val WORD_GREATER_OR_EQ = store_thm("WORD_GREATER_OR_EQ",
  `!a:'a word b. a >= b = a > b \/ (a = b)`,
  PROVE_TAC [WORD_GREATER,WORD_GREATER_EQ,WORD_LESS_OR_EQ]);

val WORD_LESS_TRANS = store_thm("WORD_LESS_TRANS",
  `!a:'a word b c. a < b /\ b < c ==> a < c`,
  RW_TAC bool_ss [WORD_LT] \\ IMP_RES_TAC LESS_TRANS
     \\ ASM_REWRITE_TAC [] \\ PROVE_TAC []);

val WORD_LESS_EQ_TRANS = store_thm("WORD_LESS_EQ_TRANS",
  `!a:'a word b c. a <= b /\ b <= c ==> a <= c`,
  RW_TAC bool_ss [WORD_LE] \\ IMP_RES_TAC LESS_EQ_TRANS
     \\ ASM_REWRITE_TAC [] \\ PROVE_TAC []);

val WORD_LESS_EQ_LESS_TRANS = store_thm("WORD_LESS_EQ_LESS_TRANS",
  `!a:'a word b c. a <= b /\ b < c ==> a < c`,
  RW_TAC bool_ss [WORD_LE,WORD_LT] \\ IMP_RES_TAC LESS_EQ_LESS_TRANS
     \\ ASM_REWRITE_TAC [] \\ PROVE_TAC []);

val WORD_LESS_LESS_EQ_TRANS = store_thm("WORD_LESS_LESS_EQ_TRANS",
  `!a:'a word b c. a < b /\ b <= c ==> a < c`,
  RW_TAC bool_ss [WORD_LE,WORD_LT] \\ IMP_RES_TAC LESS_LESS_EQ_TRANS
     \\ ASM_REWRITE_TAC [] \\ PROVE_TAC []);

val WORD_LESS_EQ_CASES = store_thm("WORD_LESS_EQ_CASES",
  `!a:'a word b. a <= b \/ b <= a`,
  RW_TAC bool_ss [WORD_LE] \\ PROVE_TAC [LESS_EQ_CASES]);

val WORD_LESS_CASES = store_thm("WORD_LESS_CASES",
  `!a:'a word b. a < b \/ b <= a`,
  PROVE_TAC [WORD_LESS_OR_EQ,WORD_LESS_EQ_CASES]);

val WORD_LESS_CASES_IMP = store_thm("WORD_LESS_CASES_IMP",
  `!a:'a word b. ~(a < b) /\ ~(a = b) ==> b < a`,
  PROVE_TAC [WORD_NOT_LESS,WORD_LESS_OR_EQ]);

val WORD_LESS_ANTISYM = store_thm("WORD_LESS_ANTISYM",
  `!a:'a word b. ~(a < b /\ b < a)`,
  PROVE_TAC [WORD_NOT_LESS,WORD_LESS_EQ_CASES]);

val WORD_LESS_EQ_ANTISYM = store_thm("WORD_LESS_EQ_ANTISYM",
  `!a:'a word b. ~(a < b /\ b <= a)`,
  PROVE_TAC [WORD_NOT_LESS]);

val WORD_LESS_EQ_REFL = store_thm("WORD_LESS_EQ_REFL",
  `!a:'a word. a <= a`,
  REWRITE_TAC [WORD_LESS_OR_EQ]);

val WORD_LESS_EQUAL_ANTISYM = store_thm("WORD_LESS_EQUAL_ANTISYM",
  `!a:'a word b. a <= b /\ b <= a ==> (a = b)`,
  PROVE_TAC [WORD_LESS_OR_EQ,WORD_LESS_ANTISYM]);

val WORD_LESS_IMP_LESS_OR_EQ = store_thm("WORD_LESS_IMP_LESS_OR_EQ",
  `!a:'a word b. a < b ==> a <= b`,
  PROVE_TAC [WORD_LESS_OR_EQ]);

val WORD_LESS_REFL = store_thm("WORD_LESS_REFL",
  `!a:'a word. ~(a < a)`,
  RW_TAC bool_ss [WORD_NOT_LESS,WORD_LESS_OR_EQ]);

val WORD_LESS_LESS_CASES = store_thm("WORD_LESS_LESS_CASES",
  `!a:'a word b. (a = b) \/ a < b \/ b < a`,
  PROVE_TAC [WORD_LESS_CASES,WORD_LESS_OR_EQ]);

val WORD_NOT_GREATER = store_thm("WORD_NOT_GREATER",
  `!a:'a word b. ~(a > b) = a <= b`,
  PROVE_TAC [WORD_GREATER,WORD_NOT_LESS]);

val WORD_LESS_NOT_EQ = store_thm("WORD_LESS_NOT_EQ",
  `!a:'a word b. a < b ==> ~(a = b)`,
  PROVE_TAC [WORD_LESS_REFL,WORD_LESS_OR_EQ]);

val WORD_NOT_LESS_EQ = store_thm("WORD_NOT_LESS_EQ",
  `!a:'a word b. (a = b) ==> ~(a < b)`,
  PROVE_TAC [WORD_LESS_REFL]);

val WORD_HIGHER = store_thm("WORD_HIGHER",
  `!a b. a >+ b = b <+ a`,
  RW_TAC arith_ss [WORD_HI,WORD_LO]);

val WORD_HIGHER_EQ = store_thm("WORD_HIGHER_EQ",
  `!a b. a >=+ b = b <=+ a`,
  RW_TAC arith_ss [WORD_HS,WORD_LS]);

val WORD_NOT_LOWER = store_thm("WORD_NOT_LOWER",
  `!a b. ~(a <+ b) = b <=+ a`,
  RW_TAC arith_ss [WORD_LO,WORD_LS]);

val WORD_NOT_LOWER_EQUAL = store_thm("WORD_NOT_LOWER_EQUAL",
  `!a b. ~(a <=+ b) = b <+ a`,
  PROVE_TAC [WORD_NOT_LOWER]);

val WORD_LOWER_OR_EQ = store_thm("WORD_LOWER_OR_EQ",
  `!a b. a <=+ b = a <+ b \/ (a = b)`,
  REWRITE_TAC [LESS_OR_EQ,WORD_LS,WORD_LO,w2n_11]);

val WORD_HIGHER_OR_EQ = store_thm("WORD_HIGHER_OR_EQ",
  `!a b. a >=+ b = a >+ b \/ (a = b)`,
  REWRITE_TAC [GREATER_OR_EQ,WORD_HS,WORD_HI,w2n_11]);

val WORD_LOWER_TRANS = store_thm("WORD_LOWER_TRANS",
  `!a b c. a <+ b /\ b <+ c ==> a <+ c`,
  PROVE_TAC [WORD_LO,LESS_TRANS]);

val WORD_LOWER_EQ_TRANS = store_thm("WORD_LOWER_EQ_TRANS",
  `!a b c. a <=+ b /\ b <=+ c ==> a <=+ c`,
  PROVE_TAC [WORD_LS,LESS_EQ_TRANS]);

val WORD_LOWER_EQ_LOWER_TRANS = store_thm("WORD_LOWER_EQ_LOWER_TRANS",
  `!a b c. a <=+ b /\ b <+ c ==> a <+ c`,
  PROVE_TAC [WORD_LS,WORD_LO,LESS_EQ_LESS_TRANS]);

val WORD_LOWER_LOWER_EQ_TRANS = store_thm("WORD_LOWER_LOWER_EQ_TRANS",
  `!a b c. a <+ b /\ b <=+ c ==> a <+ c`,
  PROVE_TAC [WORD_LS,WORD_LO,LESS_LESS_EQ_TRANS]);

val WORD_LOWER_EQ_CASES = store_thm("WORD_LOWER_EQ_CASES",
  `!a b. a <=+ b \/ b <=+ a`,
  RW_TAC bool_ss [WORD_LS,LESS_EQ_CASES]);

val WORD_LOWER_CASES = store_thm("WORD_LOWER_CASES",
  `!a b. a <+ b \/ b <=+ a`,
  PROVE_TAC [WORD_LOWER_OR_EQ,WORD_LOWER_EQ_CASES]);

val WORD_LOWER_CASES_IMP = store_thm("WORD_LOWER_CASES_IMP",
  `!a b. ~(a <+ b) /\ ~(a = b) ==> b <+ a`,
  PROVE_TAC [WORD_NOT_LOWER,WORD_LOWER_OR_EQ]);

val WORD_LOWER_ANTISYM = store_thm("WORD_LOWER_ANTISYM",
  `!a b. ~(a <+ b /\ b <+ a)`,
  PROVE_TAC [WORD_NOT_LOWER,WORD_LOWER_EQ_CASES]);

val WORD_LOWER_EQ_ANTISYM = store_thm("WORD_LOWER_EQ_ANTISYM",
  `!a b. ~(a <+ b /\ b <=+ a)`,
  PROVE_TAC [WORD_NOT_LOWER]);

val WORD_LOWER_EQ_REFL = store_thm("WORD_LOWER_EQ_REFL",
  `!a. a <=+ a`,
  REWRITE_TAC [WORD_LOWER_OR_EQ]);

val WORD_LOWER_EQUAL_ANTISYM = store_thm("WORD_LOWER_EQUAL_ANTISYM",
  `!a b. a <=+ b /\ b <=+ a ==> (a = b)`,
  PROVE_TAC [WORD_LOWER_OR_EQ,WORD_LOWER_ANTISYM]);

val WORD_LOWER_IMP_LOWER_OR_EQ = store_thm("WORD_LOWER_IMP_LOWER_OR_EQ",
  `!a b. a <+ b ==> a <=+ b`,
  PROVE_TAC [WORD_LOWER_OR_EQ]);

val WORD_LOWER_REFL = store_thm("WORD_LOWER_REFL",
  `!a. ~(a <+ a)`,
  RW_TAC bool_ss [WORD_NOT_LOWER,WORD_LOWER_OR_EQ]);

val WORD_LOWER_LOWER_CASES = store_thm("WORD_LOWER_LOWER_CASES",
  `!a b. (a = b) \/ a <+ b \/ b <+ a`,
  PROVE_TAC [WORD_LOWER_CASES,WORD_LOWER_OR_EQ]);

val WORD_NOT_HIGHER = store_thm("WORD_NOT_HIGHER",
  `!a b. ~(a >+ b) = a <=+ b`,
  PROVE_TAC [WORD_HIGHER,WORD_NOT_LOWER]);

val WORD_LOWER_NOT_EQ = store_thm("WORD_LOWER_NOT_EQ",
  `!a b. a <+ b ==> ~(a = b)`,
  PROVE_TAC [WORD_LOWER_REFL,WORD_LOWER_OR_EQ]);

val WORD_NOT_LOWER_EQ = store_thm("WORD_NOT_LOWER_EQ",
  `!a b. (a = b) ==> ~(a <+ b)`,
  PROVE_TAC [WORD_LOWER_REFL]);

(* ------------------------------------------------------------------------- *)

val w2n_word_L = SIMP_CONV arith_ss [word_L_def,w2n_n2w,LESS_MOD,
  SPEC_LESS_EXP_SUC_MONO,INT_MIN_def,dimword_def] ``w2n word_L``;

val w2n_word_H = prove(
  `w2n (word_H:'a word) = ^INT_MIN_ML - 1`,
  `^INT_MIN_ML - 1 < ^INT_MIN_ML` by SIMP_TAC arith_ss [ZERO_LT_TWOEXP]
    \\ ASSUME_TAC SPEC_LESS_EXP_SUC_MONO \\ IMP_RES_TAC LESS_TRANS
    \\ ASM_SIMP_TAC arith_ss [word_H_def,w2n_n2w,LESS_MOD,
         INT_MAX_def,INT_MIN_def,dimword_def]);

val WORD_L_PLUS_H = store_thm("WORD_L_PLUS_H",
  `word_L + word_H = word_T`,
  REWRITE_TAC [word_add_def,w2n_word_L,w2n_word_H,n2w_def]
    \\ RW_TAC (fcp_ss++ARITH_ss) [word_T,GSYM EXP,DIMINDEX_GT_0,
         DECIDE ``0 < m ==> (SUC (m - 1) = m)``,ONE_COMP_0_THM]);

fun bound_tac th1 th2 =
  RW_TAC bool_ss [WORD_LE,WORD_L_NEG,WORD_LE,WORD_H_POS,w2n_word_H,w2n_word_L]
    \\ Cases_on `word_msb a` \\ ASM_REWRITE_TAC []
    \\ Cases_on `^HB = 0`
    >> (IMP_RES_TAC th1 \\ ASM_SIMP_TAC arith_ss [])
    \\ Cases_on_word `a`
    \\ FULL_SIMP_TAC bool_ss [w2n_n2w,word_msb_n2w,dimword_def]
    \\ MAP_EVERY IMP_RES_TAC [th2,SLICE_COMP_MSB]
    \\ POP_ASSUM (SPEC_THEN `n` ASSUME_TAC)
    \\ STRIP_ASSUME_TAC EXISTS_HB
    \\ FULL_SIMP_TAC arith_ss [GSYM SLICE_ZERO_THM,GSYM BITS_ZERO3];

val WORD_L_LESS_EQ = store_thm("WORD_L_LESS_EQ",
  `!a:'a word. word_L <= a`,
  bound_tac MSB_THM1b BIT_SLICE_THM2);

val WORD_LESS_EQ_H = store_thm("WORD_LESS_EQ_H",
  `!a:'a word. a <= word_H`,
  bound_tac MSB_THM3b BIT_SLICE_THM3
    \\ `~(m = 0)` by DECIDE_TAC
    \\ METIS_TAC [SUB_LESS_OR,SLICE_MSB_LT,ADD]);

val WORD_NOT_L_EQ_H = prove(
  `~(word_L = word_H)`,
  SIMP_TAC arith_ss [GSYM w2n_11,w2n_word_L,w2n_word_H,
    GSYM ADD_EQ_SUB,ONE_LT_EQ_TWOEXP]);

val WORD_L_LESS_H = store_thm("WORD_L_LESS_H",
  `word_L < word_H`,
  PROVE_TAC [WORD_L_LESS_EQ,WORD_LESS_EQ_H,WORD_LESS_EQ_TRANS,
    WORD_NOT_L_EQ_H,WORD_LESS_OR_EQ]);

val NOT_INT_MIN_ZERO = save_thm("NOT_INT_MIN_ZERO",
  METIS_PROVE [WORD_L_NEG, WORD_0_POS] ``~(INT_MINw = 0w)``);

val ZERO_LO_INT_MIN = save_thm("ZERO_LO_INT_MIN",
  EQT_ELIM (SIMP_CONV arith_ss [WORD_LO, word_0_n2w,
    REWRITE_RULE [GSYM w2n_11] NOT_INT_MIN_ZERO]
  ``0w <+ INT_MINw``));

val WORD_0_LS = store_thm("WORD_0_LS",
  `!w. 0w <=+ w`, SRW_TAC [] [WORD_LS]);

val WORD_LS_T = store_thm("WORD_LS_T",
  `!w. w <=+ UINT_MAXw`,
  SRW_TAC [] [WORD_LS, word_T_def, UINT_MAX_def, w2n_lt,
    DECIDE ``a < b ==> a <= b - 1``]);

local
  fun Cases_on_word tm =
   Q.ISPEC_THEN tm FULL_STRUCT_CASES_TAC ranged_word_nchotomy;
in
  val tac =
    RW_TAC (std_ss++boolSimps.LET_ss) [WORD_LO, WORD_LS, w2n_n2w]
    \\ MAP_EVERY Cases_on_word [`a`,`b`,`c`]
    \\ FULL_SIMP_TAC std_ss [word_add_n2w, w2n_n2w, word_2comp_n2w]
    \\ IMP_RES_TAC (DECIDE ``~(a <= b) ==> (b <= a:num)``)
    \\ Cases_on `n + n' < dimword (:'a)`
    \\ SRW_TAC [ARITH_ss] [SUB_LEFT_LESS, SUB_RIGHT_ADD]
    >> (Cases_on `n' = 0` \\ SRW_TAC [ARITH_ss] [])
    \\ FULL_SIMP_TAC bool_ss [NOT_LESS]
    \\ `?p. p < dimword (:'a) /\ (n + n' = dimword (:'a) + p)`
    by (EXISTS_TAC `(n + n') MOD dimword (:'a)`
          \\ IMP_RES_TAC LESS_EQUAL_ADD
          \\ SRW_TAC [ARITH_ss] [ZERO_LT_dimword, ADD_MODULUS])
    \\ SRW_TAC [ARITH_ss] [ZERO_LT_dimword, ADD_MODULUS]
end;

val WORD_ADD_LEFT_LO = store_thm("WORD_ADD_LEFT_LO",
  `!b c a. a + b <+ c =
      if b <=+ c then
         let x = n2w (w2n c - w2n b) in
           a <+ x \/ ~(b = 0w) /\ $- c + x <=+ a
      else
         $-b <=+ a /\ a <+ $- b + c`, tac);

val WORD_ADD_LEFT_LS = store_thm("WORD_ADD_LEFT_LS",
  `!b c a. a + b <=+ c =
      if b <=+ c then
         let x = n2w (w2n c - w2n b) in
           a <=+ x \/ ~(b = 0w) /\ $- c + x <=+ a
      else
         $-b <=+ a /\ a <=+ $- b + c`, tac);

val WORD_ADD_RIGHT_LS = save_thm("WORD_ADD_RIGHT_LS",
  (GEN `c` o GEN `a` o GEN `b`)
  ((SIMP_CONV std_ss [COND_RAND, LET_RAND, WORD_ADD_LEFT_LO,
     GSYM WORD_NOT_LOWER] THENC SIMP_CONV std_ss [WORD_NOT_LOWER])
  ``a <=+ b + c``));

val WORD_ADD_RIGHT_LO = save_thm("WORD_ADD_RIGHT_LO",
  (GEN `c` o GEN `a` o GEN `b`)
  ((SIMP_CONV std_ss [GSYM WORD_NOT_LOWER_EQUAL, COND_RAND, LET_RAND,
      Once WORD_ADD_LEFT_LS] THENC SIMP_CONV std_ss [WORD_NOT_LOWER_EQUAL])
  ``a <+ b + c``));

val WORD_LT_LO = prove(
  `!a b. a < b =
        word_msb a /\ (~word_msb b \/ a <+ b) \/
        ~word_msb a /\ ~word_msb b /\ a <+ b`,
  NTAC 2 STRIP_TAC \\ SIMP_TAC std_ss [WORD_LT, WORD_LO]
    \\ Cases_on `word_msb a` \\ Cases_on `word_msb b`
    \\ ASM_SIMP_TAC std_ss []);

val WORD_LE_LS = prove(
  `!a b. a <= b =
        word_msb a /\ (~word_msb b \/ a <=+ b) \/
        ~word_msb a /\ ~word_msb b /\ a <=+ b`,
  NTAC 2 STRIP_TAC \\ SIMP_TAC std_ss [WORD_LE, WORD_LS]
    \\ Cases_on `word_msb a` \\ Cases_on `word_msb b`
    \\ ASM_SIMP_TAC std_ss []);

val INT_MIN_LT_dimword = prove(
  `INT_MIN (:'a) < dimword (:'a)`,
  SRW_TAC [] [INT_MIN_def, dimword_def, DIMINDEX_GT_0]);

val WORD_MSB_INT_MIN_LS = store_thm("WORD_MSB_INT_MIN_LS",
  `!a. word_msb a = INT_MINw <=+ a`,
  STRIP_TAC \\ Cases_on_word `a`
    \\ SRW_TAC [] [word_L_def, word_msb_n2w_numeric, WORD_LS,
         INT_MIN_LT_dimword]);

val WORD_LT_LO = save_thm("WORD_LT_LO",
  SIMP_RULE std_ss [WORD_MSB_INT_MIN_LS, WORD_NOT_LOWER_EQUAL] WORD_LT_LO);

val WORD_LE_LS = save_thm("WORD_LE_LS",
  SIMP_RULE std_ss [WORD_MSB_INT_MIN_LS, WORD_NOT_LOWER_EQUAL] WORD_LE_LS);

(* ------------------------------------------------------------------------- *)

val WORD_ss = rewrites
  [WORD_LT,WORD_GT,WORD_LE,WORD_GE,WORD_LS,WORD_HI,WORD_LO,WORD_HS,
   word_msb_n2w,w2n_n2w,dimword_def];

val ORDER_WORD_TAC =
  SIMP_TAC (bool_ss++boolSimps.LET_ss++WORD_ss) [] \\ DECIDE_TAC;

val word_lt_n2w = store_thm("word_lt_n2w",
  `!a b. (n2w a):'a word < n2w b =
          let sa = BIT ^HB a and sb = BIT ^HB b
          in
            (sa = sb) /\ a MOD dimword(:'a) < b MOD dimword(:'a) \/ sa /\ ~sb`,
  ORDER_WORD_TAC);

val word_gt_n2w = store_thm("word_gt_n2w",
  `!a b. (n2w a):'a word > n2w b = let sa = BIT ^HB a and sb = BIT ^HB b in
    (sa = sb) /\ a MOD dimword(:'a) > b MOD dimword(:'a) \/ ~sa /\ sb`,
  ORDER_WORD_TAC);

val word_le_n2w = store_thm("word_le_n2w",
  `!a b. (n2w a):'a word <= n2w b = let sa = BIT ^HB a and sb = BIT ^HB b in
    (sa = sb) /\ a MOD dimword(:'a) <= b MOD dimword(:'a) \/ sa /\ ~sb`,
  ORDER_WORD_TAC);

val word_ge_n2w = store_thm("word_ge_n2w",
  `!a b. (n2w a):'a word >= n2w b = let sa = BIT ^HB a and sb = BIT ^HB b in
    (sa = sb) /\ a MOD dimword(:'a) >= b MOD dimword(:'a) \/ ~sa /\ sb`,
  ORDER_WORD_TAC);

val word_ls_n2w = store_thm("word_ls_n2w",
  `!a b. (n2w a):'a word <=+ n2w b = a MOD dimword(:'a) <= b MOD dimword(:'a)`,
  ORDER_WORD_TAC);

val word_hi_n2w = store_thm("word_hi_n2w",
  `!a b. (n2w a):'a word >+ n2w b = a MOD dimword(:'a) > b MOD dimword(:'a)`,
  ORDER_WORD_TAC);

val word_lo_n2w = store_thm("word_lo_n2w",
  `!a b. (n2w a):'a word <+ n2w b = a MOD dimword(:'a) < b MOD dimword(:'a)`,
  ORDER_WORD_TAC);

val word_hs_n2w = store_thm("word_hs_n2w",
  `!a b. (n2w a):'a word >=+ n2w b = a MOD dimword(:'a) >= b MOD dimword(:'a)`,
  ORDER_WORD_TAC);

(* ------------------------------------------------------------------------- *)
(* Theorems about 0w and $- 1w                                               *)
(* ------------------------------------------------------------------------- *)

val word_reverse_0 = store_thm("word_reverse_0",
  `word_reverse 0w = 0w`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [word_0, word_reverse_def]);

val word_reverse_word_T = store_thm("word_reverse_word_T",
  `word_reverse ($- 1w) = ($- 1w)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss] [word_T, WORD_NEG_1, word_reverse_def]);

val sw2sw_0 = save_thm("sw2sw_0",
  SIMP_CONV (arith_ss++boolSimps.LET_ss)
  [word_0_n2w, sw2sw_def, BIT_ZERO, SIGN_EXTEND_def] ``sw2sw 0w``);

val sw2sw_word_T = store_thm("sw2sw_word_T",
  `sw2sw ($- 1w) = $- 1w`,
  NTAC 3 (SRW_TAC [fcpLib.FCP_ss] [sw2sw, word_T, word_msb_def, WORD_NEG_1])
    << [`i < dimindex (:'b)` by DECIDE_TAC,
      `dimindex (:'b) - 1 < dimindex (:'b)`
         by SIMP_TAC arith_ss [DIMINDEX_GT_0]]
    \\ SRW_TAC [] [word_T]);

val word_div_1 = save_thm("word_div_1",
  SIMP_CONV std_ss [word_1_n2w, word_div_def, n2w_w2n] ``v // 1w``);

val word_bit_0 = save_thm("word_bit_0",
  EQF_ELIM (SIMP_CONV std_ss [word_bit_n2w, BIT_ZERO] ``word_bit h 0w``));

val word_msb_0 = save_thm("word_msb_0",
  EQF_ELIM (SIMP_CONV std_ss [word_msb_n2w, BIT_ZERO] ``word_msb 0w``));

val word_lsb_word_T = store_thm("word_lsb_word_T",
  `word_lsb ($- 1w)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
    [word_T, word_lsb_def, WORD_NEG_1, DIMINDEX_GT_0]);

val word_msb_word_T = store_thm("word_msb_word_T",
  `word_msb ($- 1w)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
    [word_T, word_msb_def, WORD_NEG_1, DIMINDEX_GT_0]);

val word_bit_0_word_T = store_thm("word_bit_0_word_T",
  `word_bit 0 ($- 1w)`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
    [word_T, word_bit_def, WORD_NEG_1, DIMINDEX_GT_0]);

val word_log2_1 = store_thm("word_log2_1",
  `word_log2 1w = 0w`,
  SRW_TAC [] [word_log2_def, word_1_n2w, LOG2_def, logrootTheory.LOG_1]);

val word_join_0 = store_thm("word_join_0",
  `!a. word_join 0w a = w2w a`,
  SRW_TAC [boolSimps.LET_ss]
    [word_join_def, w2w_0, ZERO_SHIFT, WORD_OR_CLAUSES]);

val word_concat_0 = save_thm("word_concat_0",
  SIMP_CONV std_ss [word_join_0, w2w_0, word_concat_def] ``0w @@ 0w``);

val word_join_word_T = store_thm("word_join_word_T",
  `word_join ($- 1w) ($- 1w) = $- 1w`,
  SRW_TAC [boolSimps.LET_ss, fcpLib.FCP_ss]
       [word_join_def, w2w, word_T, word_or_def, word_lsl_def, WORD_NEG_1]
    \\ POP_ASSUM MP_TAC
    \\ Cases_on `i < dimindex (:'b)`
    \\ SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
         [fcpTheory.index_sum, w2w, word_T, DIMINDEX_GT_0]
    \\ FULL_SIMP_TAC std_ss [DECIDE ``i < 1 = (i = 0)``, DIMINDEX_GT_0]);

val word_concat_word_T = save_thm("word_concat_word_T",
  (REWRITE_RULE [word_join_word_T] o SPECL [`$- 1w`,`$- 1w`]) word_concat_def);

val BIT0_CONV = SIMP_CONV std_ss [GSYM LSB_def, LSB_ODD];

val extract_00 = prove(
  `(!a:'a word. (0 -- 0) a = if word_lsb a then 1w else 0w) /\
   (!a:'a word. (0 <> 0) a = if word_lsb a then 1w else 0w) /\
   (!a:'a word. (0 >< 0) a = if word_lsb a then 1w else 0w:'b word)`,
  SRW_TAC [fcpLib.FCP_ss]
       [n2w_def, w2w, word_bits_def, word_slice_def, word_extract_def,
        word_lsb_def, DIMINDEX_GT_0]
    \\ Cases_on `i = 0`
    \\ SRW_TAC [fcpLib.FCP_ss]
         [DIMINDEX_GT_0, BIT0_CONV ``BIT 0 1``, BIT0_CONV ``BIT 0 0``,
          (SIMP_RULE std_ss [] o SPECL [`i`,`0`]) BIT_B_NEQ, BIT_ZERO]
    \\ Cases_on `i < dimindex (:'a)`
    \\ SRW_TAC [fcpLib.FCP_ss] []);

val extract_0n = store_thm("extract_0n",
  `(!n a:'a word. (0 -- n) a = if (n = 0) /\ word_lsb a then 1w else 0w) /\
   (!n a:'a word. (0 <> n) a = if (n = 0) /\ word_lsb a then 1w else 0w) /\
   (!n a:'a word. (0 >< n) a =
      if (n = 0) /\ word_lsb a then 1w else 0w:'b word)`,
  REPEAT STRIP_TAC \\ Cases_on `n = 0`
    \\ SRW_TAC [ARITH_ss]
         [extract_00, WORD_BITS_ZERO, WORD_SLICE_ZERO, WORD_EXTRACT_ZERO]);

val lsr_1_word_T = store_thm("lsr_1_word_T",
  `$- 1w >>> 1 = INT_MAXw`,
  SRW_TAC [fcpLib.FCP_ss] [WORD_NEG_1, word_lsr_def, word_T, word_H]
    \\ Cases_on `i < dimindex (:'a) - 1`
    \\ SRW_TAC [ARITH_ss] [word_T]);

val word_rrx_0 = store_thm("word_rrx_0",
  `(word_rrx(F, 0w) = (F, 0w)) /\
   (word_rrx(T, 0w) = (F, INT_MINw))`,
  SRW_TAC [fcpLib.FCP_ss]
    [word_0, word_L, word_rrx_def, word_lsb_n2w, ZERO_SHIFT]);

val word_rrx_word_T = store_thm("word_rrx_word_T",
  `(word_rrx(F, $- 1w) = (T, INT_MAXw)) /\
   (word_rrx(T, $- 1w) = (T, $- 1w))`,
  SRW_TAC [fcpLib.FCP_ss, ARITH_ss]
    [word_T, word_rrx_def, word_lsb_word_T, lsr_1_word_T, word_H, ZERO_SHIFT,
     REWRITE_RULE [SYM WORD_NEG_1] word_T]);

val word_T_not_zero = store_thm("word_T_not_zero",
  `~($- 1w = 0w)`,
  SRW_TAC [fcpLib.FCP_ss] [REWRITE_RULE [SYM WORD_NEG_1] word_T, word_0]);

val WORD_LS_word_T = store_thm("WORD_LS_word_T",
  `(!n. $- 1w <=+ n = (n = $- 1w)) /\
   (!n. n <=+ $- 1w)`,
  REWRITE_TAC [WORD_NEG_1, WORD_LS_T]
    \\ REWRITE_TAC [WORD_LOWER_OR_EQ, METIS_PROVE
         [WORD_LS_T, WORD_NOT_LOWER] ``~(word_T <+ n)``]
    \\ METIS_TAC []);

val WORD_LS_word_0 = store_thm("WORD_LS_word_0",
  `!n. n <=+ 0w = (n = 0w)`,
  REWRITE_TAC [WORD_LOWER_OR_EQ, GSYM WORD_NOT_LOWER_EQUAL, WORD_0_LS]);

val WORD_LO_word_T = store_thm("WORD_LO_word_T",
  `(!n. ~($- 1w <+ n)) /\
   (!n. n <+ $- 1w = ~(n = $- 1w))`,
  REWRITE_TAC [WORD_NOT_LOWER, WORD_NEG_1, WORD_LS_T]
    \\ REWRITE_TAC [GSYM WORD_NOT_LOWER_EQUAL,
         GSYM WORD_NEG_1, WORD_LS_word_T]);

val WORD_LO_word_0 = store_thm("WORD_LO_word_0",
  `(!n. 0w <+ n = ~(n = 0w)) /\
   (!n. ~(n <+ 0w))`,
  REWRITE_TAC [WORD_NOT_LOWER, WORD_0_LS]
    \\ REWRITE_TAC [GSYM WORD_NOT_LOWER_EQUAL, WORD_LS_word_0]);

val WORD_LESS_0_word_T = store_thm("WORD_LESS_0_word_T",
  `~(0w < $- 1w) /\ ~(0w <= $- 1w) /\ $- 1w < 0w /\ $- 1w <= 0w`,
  REWRITE_TAC [WORD_LT, WORD_LE, word_msb_word_T, word_msb_0]);

(* ------------------------------------------------------------------------- *)
(* Support for termination proofs                                            *)
(* ------------------------------------------------------------------------- *)

fun Cases_word' (g as (_,w)) =
  let val (Bvar,_) = with_exn dest_forall w (ERR "Cases_word" "not a forall")
  in (STRIP_TAC THEN STRUCT_CASES_TAC (Drule.ISPEC Bvar ranged_word_nchotomy)) g
  end;

val SUC_WORD_PRED = store_thm("SUC_WORD_PRED", 
  `!x:'a word. ~(x = 0w) ==> (SUC (w2n (x - 1w)) = w2n x)`,
  Cases_word' \\ Cases_on `n`
  \\ FULL_SIMP_TAC std_ss [ADD1,GSYM word_add_n2w,WORD_ADD_SUB]
  \\ REPEAT STRIP_TAC
  \\ CONV_TAC (RAND_CONV (REWRITE_CONV [word_add_n2w]))
  \\ `n' < dimword (:'a)` by DECIDE_TAC  
  \\ ASM_SIMP_TAC std_ss [w2n_n2w]);

val WORD_PRED_THM = store_thm("WORD_PRED_THM",
  `!m:'a word. ~(m = 0w) ==> w2n (m - 1w) < w2n m`,
  REPEAT STRIP_TAC \\ IMP_RES_TAC SUC_WORD_PRED \\ DECIDE_TAC);

val triv_exp = Q.prove
(`!m. 0 < 2 **  m`,
  Induct THEN RW_TAC arith_ss [EXP]);

val ONE_LESS_TWO_EXP = Q.prove
(`!m. 0<m ==> 1 < 2 ** m`,
Cases THEN RW_TAC arith_ss [EXP] THEN 
 `0 < 2 ** n` by METIS_TAC [triv_exp] THEN DECIDE_TAC);

val w2n_lsr = store_thm ("w2n_lsr",
  `!w m. w2n (w >>> m) = (w2n w) DIV (2**m)`,
  Cases_word THEN 
  SIMP_TAC std_ss [ONCE_REWRITE_RULE [GSYM w2n_11] word_lsr_n2w,
       simpLib.SIMP_PROVE arith_ss [MIN_DEF] ``MIN a (a + b) = a``,
       word_bits_n2w,w2n_n2w,MOD_DIMINDEX,bitTheory.BITS_COMP_THM2] THEN
  SIMP_TAC std_ss [bitTheory.BITS_THM2]);

val LSR_LESS = store_thm("LSR_LESS",
  `!m y. ~(y = 0w) /\ 0<m ==> w2n (y >>> m) < w2n y`,
 RW_TAC arith_ss [w2n_lsr] THEN
 `~(w2n y = 0)` by METIS_TAC [n2w_w2n] THEN 
 METIS_TAC [DIV_LESS,ONE_LESS_TWO_EXP, DECIDE ``0<x = ~(x=0)``]);

val word_sub_w2n = store_thm("word_sub_w2n", 
  `!x:'a word y:'a word. y <=+ x ==> (w2n (x - y) = w2n x - w2n y)`,
  Cases_word' \\ Cases_word'
  \\ FULL_SIMP_TAC std_ss [WORD_LS,w2n_n2w]
  \\ REPEAT STRIP_TAC
  \\ `?k. n = k + n'` by METIS_TAC [LESS_EQ_EXISTS,ADD_COMM]
  \\ `k < dimword (:'a)` by DECIDE_TAC
  \\ ASM_SIMP_TAC std_ss [GSYM word_add_n2w,ADD_SUB,WORD_ADD_SUB,w2n_n2w]);

val ZERO_LE_TOP_FALSE = prove(
  `!n. 0w <= ((n2w n):'a word) = (BIT (dimindex (:'a) - 1) n = F)`,
  SRW_TAC [] [word_le_n2w,LET_DEF]
  \\ FULL_SIMP_TAC std_ss [BIT_def,BITS_def,MOD_2EXP_def,DIV_2EXP_def,ZERO_DIV,ZERO_MOD,
                           ZERO_LT_EXP,EVAL ``0 < 2``]);

val WORD_LE_EQ_LS = store_thm("WORD_LE_EQ_LS",
  `!x y. 0w <= x /\ 0w <= y ==> (x <= y = x <=+ y)`,
  Cases_word' \\ Cases_word'
  \\ FULL_SIMP_TAC std_ss [WORD_LS,w2n_n2w,word_le_n2w,LET_DEF,ZERO_LE_TOP_FALSE]);

val WORD_LT_EQ_LO = store_thm("WORD_LT_EQ_LO",
  `!x y. 0w <= x /\ 0w <= y ==> (x < y = x <+ y)`,
  Cases_word' \\ Cases_word'
  \\ FULL_SIMP_TAC std_ss [WORD_LO,w2n_n2w,word_lt_n2w,LET_DEF,ZERO_LE_TOP_FALSE]);

val WORD_ZERO_LE = store_thm("WORD_ZERO_LE",
  `!w:'a word. 0w <= w = w2n w < INT_MIN (:'a)`,
  Cases_word' \\ REWRITE_TAC [ZERO_LE_TOP_FALSE,GSYM word_msb_n2w,
                              word_msb_n2w_numeric,w2n_n2w,NOT_LESS_EQUAL]);

val WORD_ZERO_LE_SUB_LEMMA = prove(
  `!x:'a word y. 0w <= x /\ y <=+ x ==> 0w <= x - y`,
  `!m n k. m < n ==> m - k < n:num` by DECIDE_TAC 
  \\ ASM_SIMP_TAC bool_ss [WORD_ZERO_LE,WORD_LS,REWRITE_RULE [WORD_LS] word_sub_w2n]);  

val WORD_ZERO_LE_SUB = prove(
  `!x:'a word y. 0w <= y /\ y <= x ==> 0w <= x - y`,
  REPEAT STRIP_TAC
  \\ IMP_RES_TAC WORD_LESS_EQ_TRANS
  \\ MATCH_MP_TAC WORD_ZERO_LE_SUB_LEMMA
  \\ ASM_SIMP_TAC std_ss [GSYM WORD_LE_EQ_LS]);

val WORD_ZERO_LT_SUB = prove(
  `!x:'a word y. 0w < y /\ y < x ==> 0w < x - y`,
  REPEAT STRIP_TAC
  \\ IMP_RES_TAC WORD_LESS_IMP_LESS_OR_EQ
  \\ IMP_RES_TAC WORD_ZERO_LE_SUB
  \\ `(0w < x - y) \/ (0w = x - y)` by ASM_REWRITE_TAC [GSYM WORD_LESS_OR_EQ]
  \\ METIS_TAC [WORD_EQ_SUB_ZERO,WORD_LESS_NOT_EQ]);

val WORD_LT_SUB_UPPER = store_thm("WORD_LT_SUB_UPPER",
  `!x:'a word y. 0w < y /\ y < x ==> x - y < x`,
  REPEAT STRIP_TAC
  \\ IMP_RES_TAC WORD_LESS_TRANS
  \\ IMP_RES_TAC WORD_LESS_IMP_LESS_OR_EQ
  \\ IMP_RES_TAC WORD_ZERO_LE_SUB
  \\ ASM_SIMP_TAC bool_ss [WORD_LT_EQ_LO,WORD_LO]  
  \\ IMP_RES_TAC WORD_LE_EQ_LS
  \\ ASM_SIMP_TAC bool_ss [word_sub_w2n]
  \\ MATCH_MP_TAC (DECIDE ``!m k. ~(k = 0) /\ ~(m = 0) ==> m - k < m:num``) 
  \\ IMP_RES_TAC WORD_LESS_NOT_EQ
  \\ ASM_SIMP_TAC bool_ss [w2n_eq_0]);

val WORD_LE_SUB_UPPER = prove(
  `!x:'a word y. 0w <= y /\ y <= x ==> x - y <= x`,
  REPEAT STRIP_TAC
  \\ REWRITE_TAC [WORD_LESS_OR_EQ]
  \\ `(0w < y) \/ (0w = y)` by ASM_REWRITE_TAC [GSYM WORD_LESS_OR_EQ]
  \\ `(y < x) \/ (y = x)` by ASM_REWRITE_TAC [GSYM WORD_LESS_OR_EQ]
  \\ ASM_SIMP_TAC bool_ss [WORD_LT_SUB_UPPER,WORD_SUB_REFL]
  \\ METIS_TAC [WORD_SUB_RZERO]);

val WORD_SUB_LT = store_thm("WORD_SUB_LT",
  `!x:'a word y. 0w < y /\ y < x ==> 0w < x - y /\ x - y < x`,
  SIMP_TAC bool_ss [WORD_LT_SUB_UPPER,WORD_ZERO_LT_SUB]);

val WORD_SUB_LE = store_thm("WORD_SUB_LE",
  `!x:'a word y. 0w <= y /\ y <= x ==> 0w <= x - y /\ x - y <= x`,
  SIMP_TAC bool_ss [WORD_LE_SUB_UPPER,WORD_ZERO_LE_SUB]);


(* ------------------------------------------------------------------------- *)
(* Create a few word sizes                                                   *)
(* ------------------------------------------------------------------------- *)

val sizes = [2, 3, 4, 5, 6, 7, 8, 12, 16, 20, 24, 28, 30, 32, 64];

fun mk_word_size n =
  let val N = Arbnum.fromInt n
      val SN = Int.toString n
      val typ = fcpLib.index_type N
      val TYPE = mk_type("cart", [bool, typ])
      val dimindex = fcpLib.DIMINDEX N
      val finite = fcpLib.FINITE N
      val _ = save_thm("dimindex_" ^ SN, dimindex)
      val _ = save_thm("finite_" ^ SN, finite)
      val INT_MIN = save_thm("INT_MIN_" ^ SN,
                     (SIMP_RULE std_ss [dimindex] o
                      Thm.INST_TYPE [``:'a`` |-> typ]) INT_MIN_def)
      val dimword = save_thm("dimword_" ^ SN,
                     (SIMP_RULE std_ss [INT_MIN] o
                      Thm.INST_TYPE [``:'a`` |-> typ]) dimword_IS_TWICE_INT_MIN)
  in
    type_abbrev("word" ^ SN, TYPE)
  end;

val _ = List.app mk_word_size sizes;

(* ------------------------------------------------------------------------- *)

val word_index_def = Define `word_index (w:'a word) n = w ' n`;
val n2w_itself_def = Define `n2w_itself (n, (:'a)) = (n2w n): 'a word`;
val w2w_itself_def = Define `w2w_itself (:'a) w = (w2w w): 'a word`;
val sw2sw_itself_def = Define `sw2sw_itself (:'a) w = (sw2sw w): 'a word`;
val word_eq_def = Define `word_eq (v: 'a word) w = (v = w)`;

val word_extract_itself_def = Define`
  word_extract_itself (:'a) h l w = (word_extract h l w): bool ** 'a`;

val word_concat_itself_def = Define`
  word_concat_itself (:'a) v w = (word_concat v w): bool ** 'a`;

val fromNum_def = Define`
  fromNum (n, (:'a)) = n2w_itself (n MOD dimword (:'a),(:'a))`;

fun mk_index i =
  let val n = Arbnum.fromInt i
      val typ = fcpLib.index_type n
      val s = String.extract(type_to_string typ, 1, NONE)
      val w = "type word" ^ Int.toString i ^ " = " ^ s ^ " word"
  in
    [EmitML.MLSTRUCT w, EmitML.MLSIG w]
  end;


val _ = adjoin_to_theory
{sig_ps = NONE,
 struct_ps = SOME
 (fn ppstrm => let
   val S = (fn s => (PP.add_string ppstrm s; PP.add_newline ppstrm))
 in
   S "val _ = TotalDefn.termination_simps := ";
   S "   LSR_LESS :: WORD_PRED_THM :: !TotalDefn.termination_simps";
   S " ";
   S "val _ = ";
   S "  let open Lib boolSyntax numSyntax";
   S "      val word_type = type_of (fst(dest_forall(concl word_nchotomy)))";
   S "      val w2n_tm = fst(strip_comb(lhs(snd(dest_forall(concl w2n_def)))))";
   S "      val w2n_abs = list_mk_abs([mk_var(\"v1\",bool-->num),";
   S "                                  mk_var(\"v2\",alpha-->num),";
   S "                                  mk_var(\"v3\",word_type)],";
   S "                                 mk_comb(w2n_tm,mk_var(\"v3\",word_type)))";
   S "  in";
   S "  TypeBase.write";
   S "  [TypeBasePure.mk_nondatatype_info";
   S "   (word_type, ";
   S "     {nchotomy = SOME word_nchotomy,";
   S "      size = SOME (w2n_abs,CONJUNCT1(Drule.SPEC_ALL boolTheory.AND_CLAUSES)),";
   S "      encode=NONE})]";
   S "  end;"
 end)};

val _ = ConstMapML.insert ``n2w_itself``;

(*---------------------------------------------------------------------------*)
(* Ensure that n2w_itself sticks in the ConstMap, by writing some code into  *)
(* wordsTheory.sml                                                           *)
(*---------------------------------------------------------------------------*)

val _ = adjoin_to_theory
{sig_ps = NONE,
 struct_ps = SOME (fn ppstrm =>
  let val S = PP.add_string ppstrm
      fun NL() = PP.add_newline ppstrm
  in S "val _ = ConstMapML.insert (Term.prim_mk_const{Name=\"n2w_itself\",Thy=\"words\"});";
     NL(); NL()
  end)};

val _ = type_pp.pp_num_types := false;
val _ = type_pp.pp_array_types := false;

local
  open EmitML numeral_bitTheory
  val ALPHA_BETA_RULE = GEN_ALL o INST [`a` |-> `m`, `b` |-> `n`] o SPEC_ALL
  val MOD_WL =
    (CONV_RULE (STRIP_QUANT_CONV (RHS_CONV (ONCE_REWRITE_CONV [GSYM n2w_mod]))))
  val TIMES_2EXP1 =
    (GSYM o REWRITE_RULE [arithmeticTheory.MULT_LEFT_1] o
     SPECL [`x`,`1`]) bitTheory.TIMES_2EXP_def
  val n2w_w2n_RULE = REWRITE_RULE [n2w_w2n] o SPEC `w2n w`
  val word_eq_n2w = REWRITE_RULE [n2w_11] (SPECL [`n2w m`,`n2w n`] word_eq_def)
  val word_eq_n2w = n2w_w2n_RULE (GEN_ALL word_eq_n2w)
  val word_or_n2w = n2w_w2n_RULE word_or_n2w
  val word_and_n2w = n2w_w2n_RULE word_and_n2w
  val word_xor_n2w = n2w_w2n_RULE word_xor_n2w
  val word_add_n2w = n2w_w2n_RULE word_add_n2w
  val word_mul_n2w = n2w_w2n_RULE word_mul_n2w
  val word_ge_n2w = n2w_w2n_RULE word_ge_n2w
  val word_gt_n2w = n2w_w2n_RULE word_gt_n2w
  val word_hi_n2w = n2w_w2n_RULE word_hi_n2w
  val word_hs_n2w = n2w_w2n_RULE word_hs_n2w
  val word_le_n2w = n2w_w2n_RULE word_le_n2w
  val word_lo_n2w = n2w_w2n_RULE word_lo_n2w
  val word_ls_n2w = n2w_w2n_RULE word_ls_n2w
  val word_lt_n2w = n2w_w2n_RULE word_lt_n2w
  val word_join_n2w = SPECL [`n2w m`,`n2w n`] word_join_def
  val word_div_n2w = SPEC `n2w m` word_div_def
  val word_asr_n2w = SPECL [`n`,`n2w m`] word_asr_n2w
  val word_lsr_n2w = SPEC `n2w m` word_lsr_n2w
  val word_rol_n2w = SPEC `n2w m` word_rol_def
  val sw2sw_n2w = SPEC `n2w n` sw2sw_def
in
  val _ = emitML (!Globals.emitMLDir)
    ("words", OPEN ["sum", "num", "fcp", "bit"]
     :: MLSIG "type ('a, 'b) sum = ('a, 'b) sumML.sum"
     :: MLSIG "type 'a itself = 'a fcpML.itself"
     :: MLSIG "type 'a bit0 = 'a fcpML.bit0"
     :: MLSIG "type 'a bit1 = 'a fcpML.bit1"
     :: MLSIG "type num = numML.num"
     :: MLSIG "datatype 'a word = n2w_itself of num * 'a itself"
     :: MLSTRUCT "datatype 'a word = n2w_itself of num * 'a itself"
     :: List.concat (map mk_index sizes)
      @ map (DEFN o REWRITE_RULE [GSYM n2w_itself_def, GSYM w2w_itself_def,
           GSYM sw2sw_itself_def, GSYM word_concat_itself_def,
           GSYM word_extract_itself_def, word_T_def, word_L_def, word_H_def,
           TIMES_2EXP1] o ALPHA_BETA_RULE)
          [dimword_def, INT_MIN_def, UINT_MAX_def, INT_MAX_def,
           w2n_n2w, word_eq_n2w, w2w_n2w, word_or_n2w, word_lsl_n2w,
           word_bits_n2w, SPEC `c` word_bit_n2w, word_join_n2w, sw2sw_n2w,
           word_extract_n2w, word_slice_n2w, word_concat_def, word_log2_n2w,
           word_reverse_n2w, word_modify_n2w, word_lsb_n2w, word_msb_n2w,
           word_1comp_n2w, word_and_n2w, word_xor_n2w,
           word_2comp_n2w, word_div_n2w, word_sdiv_def,
           MOD_WL word_add_n2w, word_sub_def, MOD_WL word_mul_n2w,
           word_lsr_n2w, word_asr_n2w, word_ror_n2w, word_rol_n2w,
           word_rrx_n2w, REWRITE_RULE [GSYM word_index_def] word_index_n2w,
           word_ge_n2w, word_gt_n2w, word_hi_n2w, word_hs_n2w,
           word_le_n2w, word_lo_n2w, word_ls_n2w, word_lt_n2w,
           fromNum_def])
end;

(* ------------------------------------------------------------------------- *)

val _ = export_theory();
