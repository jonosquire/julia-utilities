# pegasus plotting

# Various utilities for plotting in julia

using Plots; pyplot()
using LaTeXStrings, Printf
using  Colors
using Statistics

include("pegasus_utilities.jl")



mdir = dir -> if !(isdir(dir))
                mkdir(dir)
              end

function saveSnapshots(file, outdir::String, n::Integer, clim; aspectratio=none, save_res=100)
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
            subplot=1 ,size=(400.0/aspectratio,400), dpi=save_res)
        plot!(plt,V["x"],panel2(img),xlabel=L"x\,(\rho_i)",subplot=2,ylims=get(clim,clim_str,:auto),
            legend=false)
        title!(plt,(@sprintf "t=%0.1f" V["t"]),subplot=1)

        savefig(plt,@sprintf "%s/%s/%s.%05d.png" outdir varname varname n)

        @printf "Saved %s/%s/%s.%05d.png\n" outdir varname varname n
        # display(plt)
    end
end



function DpHistogramPlot(file, outdir::String, n, xybins::Tuple)
    # Plots a (log) beta vs ∆ histogram, with basic mirror and firehose
    V = readAllVTK((file(3,n), file(4,n), file(5,n)))

    flat = x->x[:]
    plt=histogram2d(log10.(flat(V["beta"])),flat(V["Delta"]), normalize=true,
        bins=xybins,color=cgrad(:blues, scale=:log), legend=false, dpi=200)
    plot!(xybins[1], -1.0./(10.0.^xybins[1]),legend=false,line=(:dot, :black))
    plot!(xybins[1], 0.5./(10.0.^xybins[1]),line=(:dot, :black))
    xlabel!(L"$\log_{10}\beta$")
    ylabel!(L"\Delta")
    title!(plt,(@sprintf "t=%0.1f" V["t"]),subplot=1)
    save_name = @sprintf "%s/Dphist.%05d.png" outdir  n

    savefig(plt, save_name)
    @printf "Saved %s\n" save_name

    return plt
end

function hstEnergiesKinMag(file::String, outdir::String)
    # Kinetic and magnetic energy of fluctuations (i.e., fluid stuff)
    V = readHST(file)
    toplot = (:_7_1_KE, :_8_2_KE,:_9_3_KE,:_11_2_ME,:_12_3_ME)
    labels = ("EK1","EK2","EK3","EM2","EM3")
    plt = plot(xlabel = L"$t$",ylabel=L"$E_K,\,E_M$")
    for i = 1:length(toplot)
        plot!(V._1_time, V[toplot[i]],label=labels[i])
    end
    savefig(plt, outdir*"/hstEnergiesKinMag.png")

    return plt
end

function hstTotalEnergy(file::String, outdir::String)
    # Total energy, split into particle and magnetic field energy
    V = readHST(file)
    therm_total = 0.5.*(V[:_16_vp1sq]+V[:_17_vp2sq]+V[:_18_vp3sq])
    mag_total = V[:_10_1_ME]+V[:_11_2_ME]+V[:_12_3_ME]
    etot=therm_total.+mag_total
    plt = plot(xlabel = L"$t$",ylabel=L"$E_K,\,E_M$",yscale=:log)
    plot!(V._1_time, therm_total,label=("Particles"))
    plot!(V._1_time, mag_total,label=("Magnetic"))
    plot!(V._1_time, etot,label=("Total"),linecolor=:black)
    title!(@sprintf "Energy start, end = (%0.2f,%0.2f)" therm_total[1] therm_total[end] )
    savefig(plt, outdir*"/hstTotalEnergy.png")

    return plt
end

function meanDpPlot(file, outdir::String, nrange)
    # Plots ∆p/B2 as a function of time
    mindp = [];maxdp=[];meandp=[];t=[];
    min1 = x->minimum(mean(x,dims=2))
    max1 = x->maximum(mean(x,dims=2))
    mean1 = x->mean(x)
    for n in nrange
        V = readAllVTK((file(3,n), file(4,n), file(5,n)))
        push!(mindp, min1(V["FHparam"]))
        push!(maxdp, max1(V["FHparam"]))
        push!(meandp, mean1(V["FHparam"]))
        push!(t,V["t"])
    end
    plt = plot(t, [meandp meandp], fillrange=[mindp maxdp], fillalpha=0.3, c=:orange,
            xlabel = L"$t$",ylabel=L"$\Delta p/B^2$", axis=(font(14,"Times")),legend=false)

    savefig(plt, outdir*"/meanDp.png")

    return plt
end


function tarImagesFolder(dir)
    # tars the whole images folder for easier moving
    # Saves in base folder, appending name of folder onto file name
    init_dir = pwd()
    cd(dir*"output")
    outtarname = "images-"*split(pwd(),'/')[end-1]*".tar"
    @printf "Tarring to %s\n" outtarname
    run(`tar -cf $outtarname images/`)
    mv(outtarname, "../"*outtarname, force=true); cd("../")

    save_dir = pwd()
    @printf "<<<<<<<<<<<<<<>>>>>>>>>>>>>>\n"
    @printf "Saved to %s/%s\n" save_dir outtarname
    @printf "<<<<<<<<<<<<<<>>>>>>>>>>>>>>\n"
    cd(init_dir)

end
