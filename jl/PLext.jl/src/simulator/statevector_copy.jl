module StateVectorC

export _applyPauliX!, _applyHadamard!, _applyRX!, _applyRY!, _applyCX!
export applyPauliX, applyHadamard, applyRX, applyRY, applyCX

Base.@ccallable function apply1(gateLabel::String, sv::Ptr{ComplexF64}, num_elements::Int, wire::Int, inverse::Bool)::Cvoid
    sv_local = unsafe_wrap(Array, sv, num_elements; own=false)
    f = getfield(current_module(), gateLabel)
    f(sv_local, wire, inverse)
    ;
end
Base.@ccallable function apply1P(gateLabel::String, sv::Ptr{ComplexF64}, num_elements::Int, wire::Int, inverse::Bool, param::Float64)::Cvoid
    sv_local = unsafe_wrap(Array, sv, num_elements; own=false)
    f = getfield(current_module(), gateLabel)
    f(sv_local, wire, inverse, param)
    ;
end
Base.@ccallable function apply2(gateLabel::String, sv::Ptr{ComplexF64}, num_elements::Int, ctrl::Int, tgt::Int, inverse::Bool)::Cvoid
    sv_local = unsafe_wrap(Array, sv, num_elements; own=false)
    f = getfield(current_module(), gateLabel)
    f(sv_local, ctrl, tgt, inverse)
    ;
end
Base.@ccallable function apply2P(gateLabel::String, sv::Ptr{ComplexF64}, num_elements::Int, ctrl::Int, tgt::Int, inverse::Bool, param::Float64)::Cvoid
    sv_local = unsafe_wrap(Array, sv, num_elements; own=false)
    f = getfield(current_module(), gateLabel)
    f(sv_local, ctrl, tgt, inverse, param)
    ;
end

struct GateIndices
    internal::Vector{Int64}
    external::Vector{Int64}
end

mutable struct StateVector
    num_qubits::Int64
    data::Vector{ComplexF64}
end

function GateIndices(wires::Vector{Int64}, num_qubits::Int64)
    in = generateBitPatterns(wires, num_qubits)
    ex = generateBitPatterns(getIndicesAfterExclusion(wires, num_qubits), num_qubits)
    return GateIndices(in, ex)
end

function getIndicesAfterExclusion(indicesToExclude::Vector{Int64}, num_qubits::Int64)::Vector{Int64}
    indices = Vector{Int64}(1:1:num_qubits)
    filter!(x->x ∉ indicesToExclude, indices)
    return indices
end

function generateBitPatterns(qubitIndices::Vector{Int64}, num_qubits::Int64)::Vector{Int64}
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

function _applyPauliX!(sv::StateVector,
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    inverse::Bool = false)::Cvoid
    for ext_idx = externalIndices
        tmp1 = sv[1 + ext_idx + indices[1]]
        sv[1 + ext_idx + indices[1]] = sv[1 + ext_idx + indices[2]]
        sv[1 + ext_idx + indices[2]] = tmp
    end
    ;
end

function _applyHadamard!(sv::StateVector, 
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

function _applyRX!(sv::StateVector, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    param::Float64, inverse::Bool = false)::Cvoid
    c = cos(param / 2);
    js = (inverse == true) ?  -1im*sin(-param / 2) : 1im*sin(-param / 2);

    for ext_idx = externalIndices
        v1 = sv[1 + ext_idx + indices[1]]
        v2 = sv[1 + ext_idx + indices[2]]

        sv[1 + ext_idx + indices[1]] = c * v1 + js * v2
        sv[1 + ext_idx + indices[2]] = js * v1 + c * v2
    end
    ;
end

function _applyRY!( sv::StateVector, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    param::Float64, inverse::Bool = false)::Cvoid
    c = cos(param / 2);
    s = (inverse == true) ? -sin(param / 2) : sin(param / 2);

    for ext_idx = externalIndices
        v1 = sv[1 + ext_idx + indices[1]]
        v2 = sv[1 + ext_idx + indices[2]]

        sv[1 + ext_idx + indices[1]] = c * v1 - s * v2
        sv[1 + ext_idx + indices[2]] = s * v1 + c * v2
    end
    ;
end

function _applyCX!(sv::StateVector,
    indices::Vector{Int64}, 
    externalIndices::Vector{Int64}, 
    inverse::Bool = false)::Cvoid
    for ext_idx = externalIndices
        tmp1 = sv[1 + ext_idx + indices[3]]
        sv[1 + ext_idx + indices[3]] = sv[1 + ext_idx + indices[4]]
        sv[1 + ext_idx + indices[4]] = tmp
    end
    ;
end

Base.@ccallable function createSV(sv::StateVector, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire+1], length(sv));
    _applyPauliX!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyPauliX(sv::StateVector, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire+1], length(sv));
    _applyPauliX!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyHadamard(sv::StateVector, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire+1], length(sv));
    _applyHadamard!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyRX(sv::StateVector, wire::Int64, inverse::Bool, param::Float64)::Cvoid
    gi = GateIndices([wire+1], length(sv));
    _applyRX!(sv, gi.internal, gi.external, param, inverse);
end

Base.@ccallable function applyRY(sv::StateVector, wire::Int64, inverse::Bool, param::Float64)::Cvoid
    gi = GateIndices([wire+1], length(sv));
    _applyRY!(sv, gi.internal, gi.external, param, inverse);
end

Base.@ccallable function applyCX(sv::StateVector, ctrl_wire::Int64, tgt_wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([ctrl_wire+1, tgt_wire+1], length(sv));
    _applyCX!(sv, gi.internal, gi.external, inverse);
end

end