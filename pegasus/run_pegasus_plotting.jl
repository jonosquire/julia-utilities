# Run functions from pegasus_plotting.jl
include("pegasus_plotting.jl")

# Folder
folder = "/Users/jsquire/Desktop/Globus_tmps/"
folder = "/scratch/04177/tg834761/pegasus-aws/"*ARGS[1]*"/"
println(folder)
fname(outn,n) = @sprintf "%soutput/joined/particles.joined.out%01d.%05d.vtk" folder outn n

make_images = false
make_Dphists = true

outdir = folder*"output/images";
mdir(outdir)

if make_images
    lims = Dict("bv"=>(-0.5,0.5),"FHparam"=>(-3.5,3.5),"dens"=>(0.9,1.1),"ptot"=>(48.,52.))
    for nnn = 0:parse(Int64,ARGS[2])
        save_snapshot(fname, outdir, nnn,
            lims)
    end
end

if make_Dphists
    outdir = outdir*"/Dphist";
    mdir(outdir)
    beta_Delta = (1.5:0.01:2.1, -0.1:0.002:0.1)
    for nnn = 0:parse(Int64,ARGS[2])
        DpHistogramPlot(fname, outdir, nnn, beta_Delta)
    end
end
