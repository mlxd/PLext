module StateVectorP

export applyPauliX!, applyHadamard!, applyRX!, applyRY!

struct GateIndices
    internal::Vector{Int64}
    external::Vector{Int64}
    GateIndices(wires, num_qubits) = new(generateBitPatterns(wires, num_qubits), generateBitPatterns(getIndicesAfterExclusion(wires, num_qubits), num_qubits))
end

function getIndicesAfterExclusion(result::Ptr{Int64}, indicesToExclude::Vector{Int64}, num_qubits::Int64)::Cvoid
    indices = Vector{Int64}(1:1:num_qubits)
    filter!(x->x ∉ indicesToExclude, indices)
    result = Ptr{Int64}(pointer_from_objref(collect(indices)))
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
        unsafe_store!(sv, unsafe_load(sv, 1 + ext_idx + indices[2]), 1 + ext_idx + indices[1])
        unsafe_store!(sv, tmp1, 1 + ext_idx + indices[2])
    end
    ;
end

function _applyHadamard!(sv::Ptr{ComplexF64}, 
                        indices::Vector{Int64}, 
                        externalIndices::Vector{Int64}, 
                        inverse::Bool = false)::Cvoid
    for ext_idx = externalIndices
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

    for ext_idx = externalIndices
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

    for ext_idx = externalIndices
        v1 = unsafe_load(sv, 1 + ext_idx + indices[1])
        v2 = unsafe_load(sv, 1 + ext_idx + indices[2])

        unsafe_store!(sv, c * v1 - s * v2, 1 + ext_idx + indices[1])
        unsafe_store!(sv, s * v1 + c * v2, 1 + ext_idx + indices[2])
    end
    ;
end

Base.@ccallable function applyPauliX!(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool = false)::Cvoid
    gi = GateIndices([wire], log2(num_qubits));
    _applyPauliX!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyHadamard!(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool = false)::Cvoid
    gi = GateIndices([wire], log2(num_elements));
    _applyHadamard!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyRX!(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool = false)::Cvoid
    gi = GateIndices([wire], log2(num_elements));
    _applyRX!(sv, gi.internal, gi.external, inverse);
end

Base.@ccallable function applyRY!(sv::Ptr{ComplexF64}, num_elements::Int64, wire::Int64, inverse::Bool)::Cvoid
    gi = GateIndices([wire], log2(num_elements));
    _applyRY!(sv, gi.internal, gi.external, inverse);
end

end