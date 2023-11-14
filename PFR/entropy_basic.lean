import Mathlib
import Pfr.probability_space
import Pfr.neg_xlogx


/-- The purpose of this file is to develop the basic theory of Shannon entropy. -/

/- In this file, inversion will always mean inversion of real numbers. -/
local macro_rules | `($x ⁻¹)   => `(Inv.inv ($x : ℝ))

open Real
open BigOperators

/-- The entropy of a random variable. -/
noncomputable def entropy {Ω : Type*} [ProbabilitySpace Ω] [Fintype S] (X : Ω → S) := ∑ s : S, h ( P[ X ⁻¹' {s} ] )

notation:100 "H[ " X " ]" => entropy X

/-- Entropy is non-negative --/
lemma entropy_nonneg [ProbabilitySpace Ω] [Fintype S] (X : Ω → S) : 0 ≤ H[ X ] := by
  unfold entropy
  apply Finset.sum_nonneg
  intro s _
  apply h_nonneg
  . simp
  apply ProbabilitySpace.prob_le_one

/-- Entropy vanishes in the degenerate case -/
lemma entropy_zero [ProbabilitySpace Ω] (hΩ : ¬ProbabilitySpace.isNondeg Ω) [Fintype S] (X : Ω → S) : H[ X ] = 0 := by
  unfold entropy
  conv =>
    lhs; congr; rfl; ext s
    rw [ProbabilitySpace.prob_zero hΩ]
  unfold h; simp

/-- The Jensen bound --/
lemma entropy_le_log [ProbabilitySpace Ω] [Fintype S] {X : Ω → S} (hX : Measurable X): H[ X ] ≤ log (Fintype.card S) := by
  by_cases hΩ : ProbabilitySpace.isNondeg Ω
  . set N := Fintype.card S
    have : 0 < N := ProbabilitySpace.range_nonempty' hΩ hX
    unfold entropy
    have hN : log N = N * h (∑ s : S, N⁻¹ * P[ X ⁻¹' {s} ]) := by
      rw [<-Finset.mul_sum]
      norm_cast
      rw [ProbabilitySpace.totalProb hΩ hX]
      simp
      unfold h
      rw [log_inv]
      field_simp; ring
    rw [hN, <- inv_mul_le_iff, Finset.mul_sum]
    set w := fun _ : S ↦ N⁻¹
    set p := fun s : S ↦ (P[ X ⁻¹' {s} ] : ℝ)

    conv =>
      congr
      . congr; rfl
        ext s
        rw [(show N⁻¹ = w s by simp), (show P[ X ⁻¹' {s} ] = p s by simp)]
      congr; congr; rfl
      ext s
      rw [(show N⁻¹ = w s by simp), (show P[ X ⁻¹' {s} ] = p s by simp)]
    have hf := h_concave
    have h0 : ∀ s ∈ Finset.univ, 0 ≤ w s := by intros; simp
    have h1 : ∑ s in Finset.univ, w s = 1 := by
      simp
      apply mul_inv_cancel
      positivity
    have hmem : ∀ s ∈ Finset.univ, p s ∈ (Set.Icc 0 1) := by
      intro s _
      simp
      norm_cast
      exact ProbabilitySpace.prob_le_one (X ⁻¹' {s})
    convert (ConcaveOn.le_map_sum hf h0 h1 hmem)
    positivity
  rw [entropy_zero hΩ]
  positivity

/-- Equality in Jensen is attained when X is uniform.  TODO: also establish converse.  One could also remove hΩ but this seems of little use.  -/
lemma entropy_of_uniform [ProbabilitySpace Ω] (hΩ: ProbabilitySpace.isNondeg Ω) [Fintype S] {X : Ω → S} (hX : ProbabilitySpace.isUniform X) : H[ X ] = log (Fintype.card S) := by
  rcases hX with ⟨ hX1, hX2 ⟩
  unfold entropy
  conv =>
    lhs; congr; rfl; ext s
    rw [hX2 s]
  simp [h]
  have := ProbabilitySpace.range_nonempty' hΩ hX1
  field_simp
  rw [mul_comm]
  congr