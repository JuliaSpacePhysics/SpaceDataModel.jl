@testitem "FilePattern rendering" begin
    using SpaceDataModel: FilePattern
    using Dates

    p = FilePattern("https://data.elfin.ucla.edu/{probe}/l1/fgm/{t:yyyy}/{probe}_l1_fgs_{t:yyyymmdd}_v{version}.cdf")

    @test p(Date(2020, 10, 1); probe="ela", version="*") ==
          "https://data.elfin.ucla.edu/ela/l1/fgm/2020/ela_l1_fgs_20201001_v*.cdf"
    @test p("2020-10-01"; probe="ela", version="*") == p(Date(2020, 10, 1); probe="ela", version="*")

    @test_throws ArgumentError p(Date(2020, 10, 1); probe="ela")
    @test endswith(p(Date(2020, 10, 1); probe="ela", version="03"), "_v03.cdf")

    # A Date carries no hour, but an hourly pattern must still render
    @test FilePattern("f_{t:yyyymmddHH}.cdf"; cadence=Hour(1))(Date(2020, 10, 1)) == "f_2020100100.cdf"

    # Separators inside a date field and day of year
    @test FilePattern("{t:yyyy-mm-dd}/{t:yyyy}/{t:jjj}/f_{t:yyyyjjj}.cdf")(Date(2020, 10, 1)) ==
          "2020-10-01/2020/275/f_2020275.cdf"
    @test FilePattern("f_{t:yyyy-mm-ddTHH:MM:SS}.cdf"; cadence=Hour(1))(DateTime(2020, 10, 1, 5, 30)) ==
          "f_2020-10-01T05:00:00.cdf"

    # GOES monthly averages name both ends of the bin; the end is inclusive, and leap years count.
    goes = FilePattern("https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/avg/{t:yyyy}/{t:mm}/goes13/netcdf/g13_xrs_1m_{t:yyyymm}01_{t1:yyyymmdd}.nc"; cadence=Month(1))
    @test goes(Date(2012, 2)) ==
          "https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/avg/2012/02/goes13/netcdf/g13_xrs_1m_20120201_20120229.nc"
    @test goes(Date(2012, 2, 15)) == goes(Date(2012, 2))  # mid-step instants render the step's file
    @test repr(goes) == "FilePattern($(repr("https://www.ncei.noaa.gov/data/goes-space-environment-monitor/access/avg/{t:yyyy}/{t:mm}/goes13/netcdf/g13_xrs_1m_{t:yyyymm}01_{t1:yyyymmdd}.nc")); cadence = 1 month)"
end

@testitem "FilePattern rejects bad patterns" begin
    using SpaceDataModel: FilePattern
    using Dates

    # An unfilled keyword must fail at the call, not render a URL with a hole in it.
    @test_throws ArgumentError FilePattern("f_{probe}.cdf")(Date(2020, 10, 1))
    @test_throws ArgumentError FilePattern("f_{t:}.cdf")

    # A step whose URL repeats the last would fetch one file for a whole range.
    @test_throws ArgumentError FilePattern("f_{t:yyyy}.cdf"; cadence=Month(1))
    @test_throws ArgumentError FilePattern("f_{t:dd}.cdf"; cadence=Month(1))
    @test_throws ArgumentError FilePattern("f_{t:yyyymmddHH}.cdf"; cadence=Minute(10))
    @test FilePattern("f_{t:yyyymm}01.cdf"; cadence=Month(1)) isa FilePattern
    @test FilePattern("f_{t:yyyymmdd}.cdf"; cadence=Week(1)) isa FilePattern
end
