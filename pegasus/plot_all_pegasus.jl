using Plots; pyplot()
using LaTeXStrings, Printf
using  Colors
using Statistics

include("pegasus_utilities.jl")

folder = "/Users/jsquire/Desktop/Globus_tmps/"
folder = "/scratch/04177/tg834761/pegasus-aws/"*ARGS[1]*"/"
println(folder)
fname(outn,n) = @sprintf "%soutput/particles.joined.out%01d.%05d.vtk" folder outn n
nums = 0:33

outdir = folder*"output/images";
if !(isdir(outdir))
    mkdir(outdir)
end

function save_snapshot(file, outdir::String, n, clim)
    V = readAllVTK((file(3,n), file(4,n), file(5,n)))
    makeImage = a->dropdims(a,dims=3)
    panel2 = a->mean(a,dims=2)
    vname_list = ("Bcc2","Bcc3","vel1","vel2","vel3","FHparam","dens","ptot")
    for varname in vname_list
        if !(isdir(outdir*"/"*varname))
            mkdir(outdir*"/"*varname)
        end
    end
    for varname in vname_list
        if varname[1:3]=="Bcc" || varname[1:3]=="vel"
            clim_str = "bv"
        else
            clim_str = varname
        end
        img = makeImage(V[varname])
        plt=heatmap(V["x"],V["y"],img',xlabel=L"x\,(\rho_i)",ylabel=L"y\,(\rho_i)",
            color=:auto, colorbar=true,fc=:pu_or, layout = (2,1),clims=get(clim,clim_str,:auto),
            aspectratio = length(V["y"])/length(V["x"])*2.,subplot=1)
        plot!(plt,V["x"],panel2(img),xlabel=L"x\,(\rho_i)",subplot=2,ylims=get(clim,clim_str,:auto),
            legend=false)
        title!(plt,(@sprintf "t=%0.1f" V["t"]),subplot=1)

        savefig(plt,@sprintf "%s/%s/%s.%05d.png" outdir varname varname n)

        @printf "Saved %s/%s/%s.%05d.png" outdir varname varname n
        # display(plt)
    end
end

for nnn = 0:parse(Int64,ARGS[2])
    save_snapshot(fname, outdir, nnn,
        Dict("bv"=>(-0.5,0.5),"FHparam"=>(-3.5,3.5),"dens"=>(0.9,1.1),"ptot"=>(48.,52.)))
end
# n=2
# V = readAllVTK((fname(3,n), fname(4,n), fname(5,n)))
# img = a->dropdims(a,dims=3)
# plt=heatmap(V["x"],V["y"],img(V["FHparam"])')
# display(plt)


# hst = readHST("/Users/jsquire/Desktop/Globus_tmps/output/particles.hst")
#
# plot(hst._1_time, hst._7_1_KE)

#c = match(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)",b)
