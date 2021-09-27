module StateVectorTests

using Test
using PLext

@testset "StateVector Tests" begin
    @testset "Initialize test" begin
        sv = PLext.StateVector(4)
        @test length(sv.data) == 16
        PLext.init_state!(sv)
        @test sv.data[1] == 1+0im
        @test sv.data[2:end] == zeros(15).+0im
    end

    @testset "PauliX test" begin
        sv = PLext.StateVector(1)
        PLext.init_state!(sv)
        PLext.applyPauliX!(sv,1, false)
        @test sv[2] == 1 + 0im
        PLext.applyPauliX!(sv,1)
        @test sv[1] == 1 + 0im
        @test sv[2] == 0 + 0im
    end
    @testset "Hadamard test" begin
        sv = PLext.StateVector(2)
        PLext.init_state!(sv)
        PLext.applyHadamard!(sv,1)
        @test isapprox(view(sv.data, [1,3]), repeat([1/sqrt(2)], 2))
        @test isapprox(view(sv.data, [2,4]), repeat([0], 2))

        PLext.applyHadamard!(sv,2)
        @test isapprox(sv.data, repeat([1/2], 4))
        PLext.applyHadamard!(sv,1)

        @test isapprox(view(sv.data, [1,2]), repeat([1/sqrt(2)], 2))
        @test isapprox(view(sv.data, [3,4]), repeat([0], 2))

        PLext.applyHadamard!(sv,2)
        @test isapprox(sv.data[1], 1+0im)

        @test isapprox(sv.data[1], 1)
        @test isapprox(view(sv.data, 2:4), repeat([0], 3))
    end

end

end