# pegasus plotting

# Various utilities for plotting in julia

using Plots; pyplot()
using LaTeXStrings, Printf
using  Colors
using Statistics

include("pegasus_utilities.jl")



mdir = dir -> if !(isdir(outdir))
                mkdir(outdir)
              end

function save_snapshots(file, outdir::String, n, clim)
    V = readAllVTK((file(3,n), file(4,n), file(5,n)))
    makeImage = a->dropdims(a,dims=3)
    panel2 = a->mean(a,dims=2)
    vname_list = ("Bcc2","Bcc3","vel1","vel2","vel3","FHparam","dens","ptot")
    for varname in vname_list
        mdir(outdir*"/"*varname)
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
            subplot=1)
        plot!(plt,V["x"],panel2(img),xlabel=L"x\,(\rho_i)",subplot=2,ylims=get(clim,clim_str,:auto),
            legend=false)
        title!(plt,(@sprintf "t=%0.1f" V["t"]),subplot=1)

        savefig(plt,@sprintf "%s/%s/%s.%05d.png" outdir varname varname n)

        @printf "Saved %s/%s/%s.%05d.png\n" outdir varname varname n
        # display(plt)
    end
end



function DpHistogramPlot(file, outdir::String, n, bins::Tuple)
    # Plots a (log) beta vs ∆ histogram, with basic mirror and firehose
    V = readAllVTK((file(3,n), file(4,n), file(5,n)))

    flat = x->x[:]
    plt=histogram2d(log10.(flat(V["beta"])),flat(V["Delta"]), normalize=true,
        bins=(xbin,ybin),color=cgrad(:blues, scale=:log), legend=false)
    plot!(xbin, -1.0./(10.0.^xbin),legend=false,line=(:dot, :black))
    plot!(xbin, 0.5./(10.0.^xbin),line=(:dot, :black))
    xlabel!(L"$\log_{10}\beta$")
    ylabel!(L"\Delta")
    title!(plt,(@sprintf "t=%0.1f" V["t"]),subplot=1)
    save_name = @sprintf "%s/hist.%05d.png" outdir  n
    savefig(plt, save_name)

    @printf "Saved %s" save_name

    return plt
end
