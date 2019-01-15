using Plots; pyplot()
using LaTeXStrings, Printf
using  Colors
using Statistics

include("pegasus_utilities.jl")

folder = "/Users/jsquire/Desktop/Globus_tmps/"
folder = "/scratch/04177/tg834761/pegasus-aws/"*ARGS[1]*"/"
println(folder)
fname(outn,n) = @sprintf "%soutput/joined/particles.joined.out%01d.%05d.vtk" folder outn n




# n=2
# V = readAllVTK((fname(3,n), fname(4,n), fname(5,n)))
# img = a->dropdims(a,dims=3)
# plt=heatmap(V["x"],V["y"],img(V["FHparam"])')
# display(plt)


# hst = readHST("/Users/jsquire/Desktop/Globus_tmps/output/particles.hst")
#
# plot(hst._1_time, hst._7_1_KE)

#c = match(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)",b)
