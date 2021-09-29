module StateVectorM

export StateVector, GateIndices
export init_state!, getindex, setindex!, getIndicesAfterExclusion, generateBitPatterns
export applyPauliX!, applyHadamard!, applyRX!, applyRY!

import Base.getindex
import Base.setindex!

mutable struct StateVector
    num_qubits::Int64
    data::Vector{ComplexF64}
end

Base.@ccallable function create_StateVector(num_qubits::Int64)::StateVector
    return StateVector(num_qubits, zeros(2^num_qubits).+0im)
end

mutable struct StateVectorPtr
    num_qubits::Int64
    data::Ptr{ComplexF64}
end
mutable struct StateVectorRef
    num_qubits::Int64
    data::Ref{ComplexF64}
end

function init_state!(sv::StateVector)
    sv.data = zeros(2^sv.num_qubits).+0im
    sv[1] = 1 + 0im
    ;
end

struct GateIndices
    internal::Vector{Int64}
    external::Vector{Int64}
    GateIndices(wires, num_qubits) = new(generateBitPatterns(wires, num_qubits), generateBitPatterns(getIndicesAfterExclusion(wires, num_qubits), num_qubits))
end

function getindex(sv::StateVector, index::Int64)
    return getindex(sv.data, index)
end

function setindex!(sv::StateVector, value::ComplexF64, index::Int64)
    sv.data[index] = value
end

Base.@ccallable function getIndicesAfterExclusion(indicesToExclude::Vector{Int64}, num_qubits::Int64)::Vector{Int64}
    indices = Set{Int64}(1:1:num_qubits)
    for excl_idx = indicesToExclude
        pop!(indices, excl_idx);
    end
    collect(indices)
end

Base.@ccallable function generateBitPatterns(qubitIndices::Vector{Int64}, num_qubits::Int64)::Vector{Int64}
    indices = zeros(1)
    for index_it = Iterators.reverse(qubitIndices)
        value = exp2(num_qubits - index_it)
        current_size = length(indices)
        for i = 1:1:current_size
            push!(indices, indices[i] + value)
        end
    end

    return indices
end

Base.@ccallable function applyPauliX!(sv::StateVector, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    inverse::Bool = false)::Cvoid
    for ext_idx = externalIndices
        tmp1 = sv[1 + ext_idx + indices[1]]
        sv[1 + ext_idx + indices[1]] = sv[1 + ext_idx + indices[2]]
        sv[1 + ext_idx + indices[2]] = tmp1
    end
    ;
end

Base.@ccallable function applyPauliX!(sv::StateVector, wire::Int64, inverse::Bool = false)::Cvoid
    gi = GateIndices([wire], sv.num_qubits);
    applyPauliX!(sv::StateVector, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyHadamard!(sv::StateVector, 
                        indices::Vector{Int64}, 
                        externalIndices::Vector{Int64}, 
                        inverse::Bool = false)::Cvoid
    for ext_idx = externalIndices
        v1 = sv[1 + ext_idx + indices[1]]
        v2 = sv[1 + ext_idx + indices[2]]

        sv[1 + ext_idx + indices[1]] = (1/sqrt(2))*(v1 + v2)
        sv[1 + ext_idx + indices[2]] = (1/sqrt(2))*(v1 - v2)
    end
    ;
end

Base.@ccallable function applyHadamard!(sv::StateVector, wire::Int64, inverse::Bool = false)::Cvoid
    gi = GateIndices([wire], sv.num_qubits);
    applyHadamard!(sv::StateVector, gi.internal, gi.external, inverse);
end


Base.@ccallable function applyRX!(sv::StateVector, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    param::Float64, inverse::Bool = false)::Cvoid
    c = cos(param / 2);
    js = (inverse == true) ?  -1im*sin(-param / 2) : 1im*sin(-param / 2);

    for ext_idx = externalIndices
        v1 = sv[1 + ext_idx + indices[1]]
        v2 = sv[1 + ext_idx + indices[2]]

        sv[1 + ext_idx + indices[1]] = c * v1 + js * v2;
        sv[1 + ext_idx + indices[2]] = js * v1 + c * v2;
    end
    ;
end

Base.@ccallable function applyRX!(sv::StateVector, wire::Int64, inverse::Bool = false)::Cvoid
    gi = GateIndices([wire], sv.num_qubits);
    applyRX!(sv::StateVector, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyRY!(  sv::StateVector, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    param::Float64, inverse::Bool = false)::Cvoid
    c = cos(param / 2);
    s = (inverse == true) ? -sin(param / 2) : sin(param / 2);

    for ext_idx = externalIndices
        v1 = sv[1 + ext_idx + indices[1]]
        v2 = sv[1 + ext_idx + indices[2]]

        sv[1 + ext_idx + indices[1]] = c * v1 - s * v2;
        sv[1 + ext_idx + indices[2]] = s * v1 + c * v2;
    end
    ;
end

Base.@ccallable function applyRY!(sv::StateVector, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire], sv.num_qubits);
    applyRY!(sv::StateVector, gi.internal, gi.external, inverse);
end

end