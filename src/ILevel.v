Require Import String Omega Setoid Morphisms.
Require Import Morph Var.

(* Liftable morphisms from [level]s that we treat like streams *)
Definition ilevel N T M := morph level N T M.

Bind Scope morph_scope with ilevel.

Definition hd_ilevel {N T M} (f : ilevel (S N) T M) : pnset T M :=
  fun V => @f V (@l0 (N + V)).

Definition tl_ilevel {N T M} (f : ilevel (S N) T M)
  : ilevel N T M :=
  fun V l => f V (lS l).

Definition cons_ilevel {N T M} (a : pnset T M)
           (f : ilevel N T M) : ilevel (S N) T M :=
  fun V l =>
    match l with
    | succ0 => a V
    | succS l => f V l
    end.

Arguments hd_ilevel {N T M} f V /.
Arguments tl_ilevel {N T M} f V l /.
Arguments cons_ilevel {N T M} a f V !l.

(* Derived operations *)

Fixpoint swap_ilevel {N T M}
  : level N -> ilevel (S N) T M -> ilevel (S N) T M :=
  match N return level N -> ilevel (S N) T M -> ilevel (S N) T M with
  | 0 => fun l f => Empty_set_rec _ l
  | S N =>
    fun l f =>
      match l with
      | succ0 =>
          cons_ilevel (hd_ilevel (tl_ilevel f))
            (cons_ilevel (hd_ilevel f)
              (tl_ilevel (tl_ilevel f)))
      | succS l =>
          cons_ilevel (hd_ilevel f) (@swap_ilevel N T M l (tl_ilevel f))
      end
  end.
Arguments swap_ilevel {N T M} !l f.

(* Morphism definitions *)

Add Parametric Morphism {N T M} : (@hd_ilevel N T M)
    with signature eq_morph ==> eq_pnset
      as hd_ilevel_mor.
  intros * Heq; unfold hd_ilevel; intro.
  rewrite Heq; easy.
Qed.

Add Parametric Morphism {N T M} : (@tl_ilevel N T M)
    with signature eq_morph ==> eq_morph
      as tl_ilevel_mor.
  intros * Heq V l; unfold tl_ilevel.
  rewrite Heq; easy.
Qed.

Add Parametric Morphism {N T M} : (@cons_ilevel N T M)
    with signature eq_pnset ==> eq_morph ==> eq_morph
    as cons_ilevel_mor.
  intros * Heq1 * Heq2 V l; unfold cons_ilevel.
  destruct l; rewrite ?Heq1, ?Heq2; easy.
Qed.

Add Parametric Morphism {N T M l} : (@swap_ilevel N T M l)
    with signature eq_morph ==> eq_morph
    as swap_ilevel_mor.
  intros * Heq.
  induction N; destruct l; cbn.
  - rewrite ?Heq; easy.
  - rewrite IHN with (y := tl_ilevel y); rewrite ?Heq; easy.
Qed.

(* Beta and eta rules for [ilevel] operations *)

Lemma ilevel_beta_hd {N} {T : nset} {M} (a : forall V, T (M + V))
      (f : ilevel N T M) :
  hd_ilevel (cons_ilevel a f) = a.
Proof. easy. Qed.

Lemma ilevel_beta_tl {N} {T : nset} {M} (a : forall V, T (M + V))
      (f : ilevel N T M) :
  tl_ilevel (cons_ilevel a f) = f.
Proof. easy. Qed.

Lemma ilevel_eta {N T M} (f : ilevel (S N) T M) :
  cons_ilevel (hd_ilevel f) (tl_ilevel f) =m= f.
Proof.
  intros V l.
  destruct l; cbn; easy.
Qed.

Hint Rewrite @ilevel_beta_hd @ilevel_beta_tl @ilevel_eta
  : simpl_ilevels.

(* Unfolding derived operations *)

Lemma unfold_swap_ilevel_zero {N T M} (f : ilevel (S (S N)) T M) :
  swap_ilevel l0 f
  = cons_ilevel (hd_ilevel (tl_ilevel f))
      (cons_ilevel (hd_ilevel f)
        (tl_ilevel (tl_ilevel f))).
Proof. easy. Qed.

Lemma unfold_swap_ilevel_succ {N T M} s (f : ilevel (S (S N)) T M) :
  swap_ilevel (lS s) f
  = cons_ilevel (hd_ilevel f) (swap_ilevel s (tl_ilevel f)).
Proof. easy. Qed.

Hint Rewrite @unfold_swap_ilevel_zero @unfold_swap_ilevel_succ
  : unfold_ilevels.

(* Folding derived operations *)

Lemma fold_swap_ilevel_zero {N T M} (f : ilevel (S (S N)) T M) :
  cons_ilevel (hd_ilevel (tl_ilevel f))
      (cons_ilevel (hd_ilevel f)
        (tl_ilevel (tl_ilevel f)))
      = swap_ilevel l0 f.
Proof. easy. Qed.

Lemma fold_swap_ilevel_succ {N T M} s (f : ilevel (S (S N)) T M) :
  cons_ilevel (hd_ilevel f) (swap_ilevel s (tl_ilevel f))
  = swap_ilevel (lS s) f.
Proof. easy. Qed.

Hint Rewrite @fold_swap_ilevel_zero @fold_swap_ilevel_succ
  : fold_ilevels.

(* Simplify [ilevel] terms by unfolding, simplifying and folding *)
Ltac simpl_ilevels :=
  autorewrite with unfold_ilevels;
  autorewrite with simpl_ilevels;
  repeat progress
    (cbn;
     try (rewrite_strat topdown (hints simpl_ilevels)));
  autorewrite with fold_ilevels.

(* There is a full covariant functor from [T O] to [ilevel N T O]
   by composition.

   Such composition distributes over our operations. *)

Lemma hd_ilevel_compose_distribute {N T M R L}
      (f : ilevel (S N) T M) (g : morph T M R L) :
  morph_apply g (hd_ilevel f) =p= hd_ilevel (g @ f).
Proof. easy. Qed.

Lemma tl_ilevel_compose_distribute {N T M R L}
      (f : ilevel (S N) T M) (g : morph T M R L) :
  g @ (tl_ilevel f) =m= tl_ilevel (g @ f).
Proof. easy. Qed.

Lemma cons_ilevel_compose_distribute {N T M R L} a
      (f : ilevel N T M) (g : morph T M R L) :
  g @ (cons_ilevel a f) =m= cons_ilevel (morph_apply g a) (g @ f).
Proof.
  intros V l.
  destruct l; easy.
Qed.

Lemma swap_ilevel_compose_distribute {N T M R L} l
      (f : ilevel (S N) T M) (g : morph T M R L) :
  g @ (swap_ilevel l f) =m= swap_ilevel l (g @ f).
Proof.
  induction N; destruct l; cbn.
  - rewrite !cons_ilevel_compose_distribute,
      !hd_ilevel_compose_distribute, !tl_ilevel_compose_distribute.
    easy.
  - rewrite cons_ilevel_compose_distribute,
      hd_ilevel_compose_distribute, IHN.
    easy.
Qed.

(* Morphism extension distributes over the operations *)

Lemma hd_ilevel_extend {N T M} (f : ilevel (S N) T M) :
  pnset_extend (hd_ilevel f)
  =p= hd_ilevel (morph_extend f).
Proof.
  intros V; simplT; easy.
Qed.

Lemma tl_ilevel_extend {N T M} (f : ilevel (S N) T M) :
  morph_extend (tl_ilevel f)
  =m= tl_ilevel (morph_extend f).
Proof.
  intros V v; simplT; easy.
Qed.

Lemma cons_ilevel_extend {N T M}
      (a : pnset T M) (f : ilevel N T M) :
  morph_extend (cons_ilevel a f)
  =m= cons_ilevel (pnset_extend a) (morph_extend f).
Proof.
  intros V v.
  destruct v.
  - fold level plus.
    change (@succ0 (@Succ (level (N + V))))
      with (@l0 (S (N + V))).
    simplT; easy.
  - fold level plus in *.
    change (@Succ (level (N + V)))
      with (level (S (N + V))) in s.
    change (@succS (@Succ (level (N + V))))
      with (@lS (S (N + V))).
    simplT; easy.
Qed.

Lemma swap_ilevel_extend {N T M} l (f : ilevel (S N) T M) :
  morph_extend (swap_ilevel l f)
  =m= swap_ilevel (level_extend l) (morph_extend f).
Proof.
  induction N; destruct l; cbn.
  - rewrite !cons_ilevel_extend,
      !hd_ilevel_extend, !tl_ilevel_extend.
    easy.
  - rewrite cons_ilevel_extend,
      hd_ilevel_extend, IHN, tl_ilevel_extend.
    easy.
Qed.