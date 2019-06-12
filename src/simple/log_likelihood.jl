"""
    loglik(η, x)

Compute the simple (linear) birth and death process log-likelihood where
``η = (λ, μ)^{\\prime}``, `λ` is the birth rate, `μ` is the death rate, and `x`
is the observed sample.

Define `i` as the size of the population at time 0 and `j` as the population
size at time `t`. Let ``α = (μ e^{(λ - μ) t} - μ) / (λ e^{(λ - μ) t} - μ)`` and
``β = (λ e^{(λ - μ) t} - λ) / (λ e^{(λ - μ) t} - μ)``. Transition probability
`p(j | i, t, λ, μ)` is equal to (Bailey, 1964):
``\\sum_{h = 0}^{\\min(i, j)} \\binom{i}{h} \\binom{i + j - h - 1}{i - 1}
α^{i - h} β^{j - h} (1 - α - β)^{h}``.

Suppose to observe the process at time points `t[0], t[1], ..., t[s], ..., t[S]`
with `t[S] <= T`, at which the population size is
`n[0], n[1], ..., n[s], ..., n[S]`. By the Markov property, log-likelihood is
``l(λ, μ | x) = \\log p(n[S] | n[S], T - t[S], λ, μ) +
\\sum_{s = 1}^{S} \\log p(n[s] | n[s - 1], t[s] - t[s - 1], λ, μ)``.
If we observe `M` independent processes with same parameters `(λ, μ)`, then
``l(λ, μ | x[1], ..., x[M]) = \\sum_{m = 1}^{M} l(λ, μ | x[m]).``

If the process is observed continously over time period `[0, T]`, log-likelihood
simplifies to (Darwin, 1956, Equation (24)):
``l(λ, μ | x) = \\sum_{s=0}^{S - 1} n[s] + B \\log λ + D \\log μ - (λ + μ) X``.
`B` and `D` are the total number of births and deaths observed in `[0, T]`
respectively. `X` is defined as ``n[0] (t[1] - t[0]) + n[1] (t[2] - t[1]) + ...
+ n[S - 1] (t[S] - t[S-1]) + n[S] (T - t[S])``.

# References:

Bailey, N. T. J. (1964). The elements of stochastic processes with applications
to the natural sciences. Wiley, New York, NY, USA. ISBN 0-471-04165-3.

Darwin, J. H. (1956). The behaviour of an estimator for a simple birth and death
process. Biometrika, 43(1/2), 23-31. https://doi.org/10.2307/2333575
"""
function loglik(
  η::Vector{F},
  x::ObservationContinuousTime
)::F where {
  F <: AbstractFloat
}
  x.sum_log_n +
  x.tot_births * log(η[1]) +
  x.tot_deaths * log(η[2]) -
  (η[1] + η[2]) * x.integrated_jump
end

function loglik(
  η::Vector{F},
  x::Vector{ObservationContinuousTime{F}}
)::F where {
  F <: AbstractFloat
}
  B = zero(F)
  D = zero(F)
  T = zero(F)
  N = zero(F)

  for i = 1:length(x)
    B += x[i].tot_births
    D += x[i].tot_deaths
    T += x[i].integrated_jump
    N += x[i].sum_log_n
  end

  N + B * log(η[1]) + D * log(η[2]) - (η[1] + η[2]) * T
end

function loglik(
  η::Vector{F},
  x::ObservationDiscreteTimeEqual
) where {
  F <: AbstractFloat
}
  ll = zeros(F, x.n)

  for i = 1:x.n
    itr = zip(x.state[1:(end - 1), i], x.state[2:end, i])
    ll[i] = mapreduce(y -> trans_prob(y..., x.u, η), +, itr)
  end

  sum(ll)
end

function loglik(
  η::Vector{F},
  x::ObservationDiscreteTimeUnequal
) where {
  F <: AbstractFloat
}
  itr = zip(x.state[1:(end - 1), i], x.state[2:end, i], x.waiting_time)
  mapreduce(y -> trans_prob(y..., η), +, itr)
end

function loglik(
  η::Vector{F},
  x::Vector{ObservationDiscreteTimeUnequal}
)::F where {
  F <: AbstractFloat
}
  mapreduce(y -> loglik(η, y), +, x)
end
