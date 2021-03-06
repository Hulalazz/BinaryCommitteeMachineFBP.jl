# This file is a part of BinaryCommitteeMachineFBP.jl. License is MIT: http://github.com/carlobaldassi/BinaryCommitteeMachineFBP.jl/LICENCE.md

module AtanhErf

export atanherf, batanherf

using StatsFuns
VERSION >= v"0.6.0-dev.2767" && using SpecialFunctions
using JLD
using Interpolations
using Compat

const builddir = joinpath(dirname(@__FILE__), "..", "deps", "builds")
batanherf(x::Float64) = Float64(atanh(erf(big(x))))

let
    const mm = 16.0
    const st = 1e-4
    const r = 1.0:st:mm
    const rb = big(first(r)):big(step(r)):big(last(r)) # TODO: use big.(r) when julia 0.5 support is dropped

    const interp_degree = Quadratic
    const interp_boundary = Line
    const interp_type = Interpolations.BSplineInterpolation{Float64,1,Vector{Float64},
                                                            BSpline{interp_degree{interp_boundary}},
                                                            OnGrid,0}

    function getinp!()
        isdir(builddir) || mkdir(builddir)
        filename = joinpath(builddir, "atanherf_interp.max_$mm.step_$st.jld")
        if isfile(filename)
            inp = load(filename, "inp")
        else
            info("Computing atanh(erf(x)) table, this may take a while...")
            inp = setprecision(BigFloat, 512) do
                interpolate!(Float64[atanh(erf(x)) for x in rb], BSpline(interp_degree(interp_boundary())), OnGrid())
            end
            save(filename, Dict("inp"=>inp))
        end
        return inp::interp_type
    end

    const inp = getinp!()

    global atanherf_interp
    atanherf_interp(x::Float64) = inp[(x - first(r)) / step(r) + 1]::Float64
end

function atanherf_largex(x::Float64)
    x² = x^2
    t = 1/x²

    return sign(x) * (2log(abs(x)) + log4π + 2x² +
                      t * @evalpoly(t,
                                    1,
                                    -1.25,
                                    3.0833333333333335,
                                    -11.03125,
                                    51.0125,
                                    -287.5260416666667,
                                    1906.689732142857,
                                    -14527.3759765625,
                                    125008.12543402778,
                                    -1.1990066259765625e6)
                     ) / 4
end

function atanherf(x::Float64)
    ax = abs(x)
    ax ≤ 2 && return atanh(erf(x))
    ax ≤ 15 && return sign(x) * atanherf_interp(ax)
    return atanherf_largex(x)
end

end
