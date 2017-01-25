module LatticeBasisReduction

export gram_schmidt, LLL

include("misc.jl")
include("gram_schmidt.jl")

"""
    LLL(x::Array, α::Number[, verbose=Bool])

Return an α-reduced basis of the lattice generated by `x`, where 1/4 < α <= 1.
If verbose is set to true, also print the return/exchange operations.

# Example

```
julia> x = [[-2 7 7 -5]
       [3 -2 6 -1]
       [2 -8 -9 -7]
       [8 -9 6 -4]]
4×4 Array{Int64,2}:
 -2   7   7  -5
  3  -2   6  -1
  2  -8  -9  -7
  8  -9   6  -4

julia> LLL(x, 1, verbose=true)
iteration 1      exchange    k=2
iteration 2      reduce      k=2     ℓ=1     [μ[k,l]] = 1.0
iteration 3      reduce      k=3     ℓ=2     [μ[k,l]] = -1.0
iteration 4      reduce      k=3     ℓ=1     [μ[k,l]] = -1.0
iteration 5      exchange    k=4
iteration 6      reduce      k=3     ℓ=2     [μ[k,l]] = -1.0
iteration 7      exchange    k=3
iteration 8      reduce      k=2     ℓ=1     [μ[k,l]] = 1.0
iteration 9      reduce      k=3     ℓ=2     [μ[k,l]] = 1.0
iteration 10     reduce      k=3     ℓ=1     [μ[k,l]] = -1.0
iteration 11     reduce      k=4     ℓ=3     [μ[k,l]] = -1.0
iteration 12     exchange    k=4
iteration 13     reduce      k=3     ℓ=2     [μ[k,l]] = 1.0
iteration 14     exchange    k=3
iteration 15     exchange    k=2
iteration 16     exchange    k=3
iteration 17     reduce      k=2     ℓ=1     [μ[k,l]] = 1.0
iteration 18     exchange    k=2
iteration 19     exchange    k=4
iteration 20     reduce      k=3     ℓ=2     [μ[k,l]] = 1.0
iteration 21     exchange    k=3
iteration 22     reduce      k=2     ℓ=1     [μ[k,l]] = -1.0
iteration 23     exchange    k=2
4×4 Array{Float64,2}:
  2.0   3.0   1.0   1.0
  2.0   0.0  -2.0  -4.0
 -2.0   2.0   3.0  -3.0
  3.0  -2.0   6.0  -1.0
```

"""
function LLL{T1<:AbstractFloat, T2<:AbstractFloat}(x::Array{T1, 2}, α::T2; verbose::Bool = false)

    @assert 1/4 < α <= 1 ["Invalid value of α."]

    y = copy(x)
    n = size(y)[2]

    ystar, μ = gram_schmidt(y, ret_coef_mat=true)

    gammax = sum(ystar .* ystar, 2)

    ##### Internal Methods ##########################################
    function reduce(k, ℓ)
        if abs(μ[k, ℓ]) > 1/2
            if verbose
                println("iteration $n_iter \t reduce \t k=$k \t ℓ=$ℓ \t [μ[k,l]] = $(round_ties_down(μ[k,ℓ]))")
                n_iter += 1
            end

            y[k, :] -= round_ties_down(μ[k, ℓ]) * y[ℓ, :]
            for j in 1:ℓ-1
                μ[k, j] -= round_ties_down(μ[k, ℓ]) * μ[ℓ, j]
            end
            μ[k, ℓ] -= round_ties_down(μ[k, ℓ])
        end
    end

    function exchange(k)
        if verbose
            println("iteration $n_iter \t exchange \t k=$k")
            n_iter += 1
        end

        y[k-1, :], y[k, :] = y[k, :], y[k-1, :]
        nu = μ[k, k-1]
        δ = gammax[k] + nu^2 * gammax[k-1]
        μ[k, k-1] = nu * gammax[k-1] / δ
        gammax[k] = gammax[k] * gammax[k-1] / δ
        gammax[k-1] = δ

        for j in 1:k-2
            μ[k-1, j], μ[k, j]= μ[k, j], μ[k-1, j]
        end

        for i in k+1:n
            ξ = μ[i, k]
            μ[i, k] = μ[i, k-1] - nu * μ[i, k]
            μ[i, k-1] = μ[k, k-1] * μ[i, k] + ξ
        end
    end

    ##### Main Loop  ################################################
    n_iter = 1
    k = 2
    while k <= n
        reduce(k, k-1)
        if gammax[k] >= (α - μ[k, k-1]^2) * gammax[k-1]
            for ℓ = k-2 : -1 : 1
                reduce(k, ℓ)
            end
            k += 1
        else
            exchange(k)
            if k > 2
                k -= 1
            end
        end
    end
    return y
end

function LLL{T1<:AbstractFloat, T2<:Integer}(x::Array{T1, 2}, α::T2; verbose::Bool = false)
    LLL(x, float(α), verbose=verbose)
end

function LLL{T1<:Integer, T2<:AbstractFloat}(x::Array{T1, 2}, α::T2; verbose::Bool = false)
    LLL(float(x), α, verbose=verbose)
end

function LLL{T1<:Integer, T2<:Integer}(x::Array{T1, 2}, α::T2; verbose::Bool = false)
    LLL(float(x), float(α); verbose=verbose)
end

end
