# Run functions from pegasus_plotting.jl
include("pegasus_plotting.jl")

# Runs various functions for plotting a pegasus run.
# This is mostly meant to be run automatically on a script, not produce fancy plots

# Folder
# folder = "/Users/jsquire/Desktop/Globus_tmps/"
folder = "/scratch/04177/tg834761/pegasus-aws/"*ARGS[1]*"/"
println(folder)
fname(outn,n) = @sprintf "%soutput/joined/particles.joined.out%01d.%05d.vtk" folder outn n

make_images = true
make_Dphists = true
make_hstKinMag = true
make_hstTotalEnergy = true
make_meanDp = true
tar_everything = true # Create a conveniently named .tar with all the images

outdir = folder*"output/images";
mdir(outdir)

nlow = parse(Int64,ARGS[2])
nhigh = parse(Int64,ARGS[3])

if make_images
    lims = Dict("bv"=>(-1.,1.),"FHparam"=>(-1.5,1.5),"dens"=>(0.9,1.1),"ptot"=>(3.,7.))
    for nnn = nlow:nhigh
        saveSnapshots(fname, outdir, nnn, lims, aspectratio=0.25, save_res = 300)
    end
end

if make_Dphists
    hist_outdir = outdir*"/Dphist";
    mdir(hist_outdir)
    beta_Delta = (0:0.01:1.5, -0.5:0.01:0.5)
    for nnn = nlow:nhigh
        DpHistogramPlot(fname, hist_outdir, nnn, beta_Delta)
    end
end

if make_hstKinMag
    hstEnergiesKinMag(folder*"output/particles.hst", outdir)
end

if make_hstTotalEnergy
    hstTotalEnergy(folder*"output/particles.hst", outdir)
end

if make_meanDp
    meanDpPlot(fname, outdir, nlow:nhigh)
end

if tar_everything
    tarImagesFolder(folder)
end
