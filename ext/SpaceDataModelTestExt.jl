module SpaceDataModelTestExt

using Test
using SpaceDataModel: getdata, times, hastimedim, _time
import SpaceDataModel.Testing: test_dataset

function test_dataset(ds, var, t0, t1; empty = nothing)
    @testset "test_dataset($ds, $(repr(var)))" begin
        v = getdata(ds[var], t0, t1)
        @test !isempty(v)
        whole = getdata(ds, t0, t1)[var]
        @test isequal(whole, v)
        if hastimedim(v)
            from, to = _time(t0), _time(t1)
            ts = times(v)
            @test all(t -> from <= t < to, ts)
            @test isequal(times(whole), ts)
        end
        isnothing(empty) || @test isempty(getdata(ds[var], empty...))
    end
end

end
