module StateVectorP

using Distributed

export applyPauliX!, applyHadamard!, applyRX!, applyRY!

struct GateIndices
    internal::Vector{Int64}
    external::Vector{Int64}
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

function _applyPauliX!(sv::Ptr{ComplexF64},
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    inverse::Bool = false)::Cvoid
    for ext_idx = externalIndices
        tmp1 = unsafe_load(sv, 1 + ext_idx + indices[1])
        r1 = remotecall(unsafe_load, sv, 1 + ext_idx + indices[2])
        remotecall(unsafe_store!, sv, fetch(r1), 1 + ext_idx + indices[1])
        remotecall(unsafe_store!, sv, tmp1, 1 + ext_idx + indices[1])
        
        #unsafe_store!(sv, unsafe_load(sv, 1 + ext_idx + indices[2]), 1 + ext_idx + indices[1])
        #unsafe_store!(sv, tmp1, 1 + ext_idx + indices[2])
    end
    ;
end

function _applyHadamard!(sv::Ptr{ComplexF64}, 
                        indices::Vector{Int64}, 
                        externalIndices::Vector{Int64}, 
                        inverse::Bool = false)::Cvoid
    Threads.@threads for ext_idx = externalIndices
        v1 = unsafe_load(sv, 1 + ext_idx + indices[1])
        v2 = unsafe_load(sv, 1 + ext_idx + indices[2])

        unsafe_store!(sv, (1/sqrt(2))*(v1 + v2), 1 + ext_idx + indices[1])
        unsafe_store!(sv, (1/sqrt(2))*(v1 - v2), 1 + ext_idx + indices[2])
    end
    ;
end

function _applyRX!(sv::Ptr{ComplexF64}, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    param::Float64, inverse::Bool = false)::Cvoid
    c = cos(param / 2);
    js = (inverse == true) ?  -1im*sin(-param / 2) : 1im*sin(-param / 2);

    Threads.@threads for ext_idx = externalIndices
        v1 = unsafe_load(sv, 1 + ext_idx + indices[1])
        v2 = unsafe_load(sv, 1 + ext_idx + indices[2])

        unsafe_store!(sv, c * v1 + js * v2, 1 + ext_idx + indices[1])
        unsafe_store!(sv, js * v1 + c * v2, 1 + ext_idx + indices[2])
    end
    ;
end

function _applyRY!( sv::Ptr{ComplexF64}, 
                    indices::Vector{Int64}, 
                    externalIndices::Vector{Int64}, 
                    param::Float64, inverse::Bool = false)::Cvoid
    c = cos(param / 2);
    s = (inverse == true) ? -sin(param / 2) : sin(param / 2);

    Threads.@threads for ext_idx = externalIndices
        v1 = unsafe_load(sv, 1 + ext_idx + indices[1])
        v2 = unsafe_load(sv, 1 + ext_idx + indices[2])

        unsafe_store!(sv, c * v1 - s * v2, 1 + ext_idx + indices[1])
        unsafe_store!(sv, s * v1 + c * v2, 1 + ext_idx + indices[2])
    end
    ;
end

function _applyCX!(sv::Ptr{ComplexF64},
    indices::Vector{Int64}, 
    externalIndices::Vector{Int64}, 
    inverse::Bool = false)::Cvoid
    Threads.@threads for ext_idx = externalIndices
        tmp1 = unsafe_load(sv, 1 + ext_idx + indices[3])
        unsafe_store!(sv, unsafe_load(sv, 1 + ext_idx + indices[4]), 1 + ext_idx + indices[3])
        unsafe_store!(sv, tmp1, 1 + ext_idx + indices[4])
    end
    ;
end

Base.@ccallable function applyPauliX(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire+1], Int64(log2(num_elements)));
    _applyPauliX!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyHadamard(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire+1], Int64(log2(num_elements)));
    _applyHadamard!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyRX(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool, param::Float64)::Cvoid
    gi = GateIndices([wire+1], Int64(log2(num_elements)));
    _applyRX!(sv, gi.internal, gi.external, param, inverse);
end

Base.@ccallable function applyRY(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool, param::Float64)::Cvoid
    gi = GateIndices([wire+1], Int64(log2(num_elements)));
    _applyRY!(sv, gi.internal, gi.external, param, inverse);
end

Base.@ccallable function applyCX(sv::Ptr{ComplexF64}, num_elements::Int64, ctrl_wire::Int64, tgt_wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([ctrl_wire+1, tgt_wire+1], Int64(log2(num_elements)));
    _applyCX!(sv, gi.internal, gi.external, inverse);
end

end