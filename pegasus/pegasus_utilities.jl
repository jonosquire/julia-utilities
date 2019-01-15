using DelimitedFiles, DataFrames


function readVTK(s::String)

    # Output tuple
    V=Dict()
    # Read in file
    io = open(s, "r")
    tmp = readline(io) # vtk DataFile Version 3.0
    # c = match(r"[+-]? *(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)",b)
    V["t"] = parse(Float64, readline(io)[25:38])  # Athena++ data at time=%f  cycle=%d variables=...

    tmp = readline(io) # BINARY
    tmp = readline(io) # DATASET RECTILINEAR_GRID
    dims = readdlm(IOBuffer(readline(io)[12:end]),' ', Int64) .- 1# DIMENSIONS NX NY NZ

    # Generate coordinates
    readFloat32(io::IOStream,n::Integer) =
        map(x->Float64(ntoh(x)),reinterpret(Float32,read(io, 4*n)))
    avGrid(x::Array) = 0.5*(x[1:end-1]+x[2:end])
    nx = parse(Int32, readline(io)[14:end-5]) # X_COORDINATES nx float
    nx-1==dims[1] ? V["x"] = avGrid(readFloat32(io, nx)) : error("Dimensions dont match")
    readline(io)
    ny = parse(Int32, readline(io)[14:end-5]) # Y_COORDINATES ny float
    ny-1==dims[2] ? V["y"] = avGrid(readFloat32(io, ny)) : error("Dimensions dont match")
    readline(io)
    nz = parse(Int32, readline(io)[14:end-5]) # Z_COORDINATES nz float
    nz-1==dims[3] ? V["z"] = avGrid(readFloat32(io, nz)) : error("Dimensions dont match")
    readline(io)
    V["dims"]=dims

    n2read = parse(Int32, readline(io)[11:end]) # CELL_DATA NXNYNZ
    replace!(dims, 0=>1)
    prod(dims) != n2read ? error("dims not the same as n2read") :

    tmp = readline(io)
    while !eof(io)
        if occursin(r"SCALARS",tmp)
            namestr = readdlm(IOBuffer(tmp),' ', String)[2]
            tmp = readline(io)
            V[namestr]=reshape(readFloat32(io,n2read),dims[1],dims[2],dims[3])
            readline(io)
            tmp = readline(io)
        elseif occursin(r"VECTOR",tmp)
            namestr = readdlm(IOBuffer(tmp),' ', String)[2]
            V[namestr]=reshape(readFloat32(io,3*n2read),3,dims[1],dims[2],dims[3])
            readline(io)
            tmp = readline(io)
        else
            error("Unrecognized descriptor: "*tmp)
        end
    end

    # Tidy up some of the vectors
    if "Bcc" in keys(V)
        V["Bcc1"] = V["Bcc"][1,:,:,:]
        V["Bcc2"] = V["Bcc"][2,:,:,:]
        V["Bcc3"] = V["Bcc"][3,:,:,:]
        delete!(V,"Bcc")
    end
    if "vel" in keys(V)
        V["vel1"] = V["vel"][1,:,:,:]
        V["vel2"] = V["vel"][2,:,:,:]
        V["vel3"] = V["vel"][3,:,:,:]
        delete!(V,"vel")
    end
    if "mom1" in keys(V)
        V["vel1"] = V["mom1"]./V["dens"]
        V["vel2"] = V["mom2"]./V["dens"]
        V["vel3"] = V["mom3"]./V["dens"]
    end

    return V
end


function readAllVTK(vtkfiles::Tuple)
    # Reads a VTK files, or VTK files at a given timestep (e.g., if B, V P in
    # different out{N} files), then puts them together and calculates other useful
    # things like pressure anisotropy.

    # Obviously, all the vtk files should be at the same time
    # vtkfiles should be a tuple list of different filenames

    nvtk = length(vtkfiles)
    V=Dict();
    for nnn=1:nvtk
        tmp=readVTK(vtkfiles[nnn])
        fields = keys(tmp)
        for name in fields
            V[name] = tmp[name];
        end
    end

    # Compute pressure anisotropy and other useful bits if possible
    if "pressure_tensor_11" in keys(V)
        V["bsq"]  = V["Bcc1"].^2 + V["Bcc2"].^2 + V["Bcc3"].^2;
        V["ptot"] = ( V["pressure_tensor_11"] + V["pressure_tensor_22"] + V["pressure_tensor_33"] )/3.;
        V["pprl"] = (V["Bcc1"].*V["Bcc1"].*V["pressure_tensor_11"] + V["Bcc3"].*V["Bcc3"].*V["pressure_tensor_33"])./V["bsq"]
                .+ V["Bcc2"].*( V["pressure_tensor_12"].*V["Bcc1"] + V["pressure_tensor_22"].*V["Bcc2"] + V["pressure_tensor_23"].*V["Bcc3"] )./V["bsq"]
                .+ (V["pressure_tensor_12"].*V["Bcc2"] + V["pressure_tensor_13"].*V["Bcc3"] ).*V["Bcc1"]./V["bsq"]
                .+ V["Bcc3"].*( V["pressure_tensor_13"].*V["Bcc1"] + V["pressure_tensor_23"].*V["Bcc2"])./V["bsq"]
        V["pprp"] = 1.5 * V["ptot"] - 0.5 * V["pprl"];
        V["Delta"]= 1.0 .- V["pprl"]./V["pprp"];
        V["FHparam"] = (V["pprp"]-V["pprl"])./V["bsq"];
        V["beta"] = 2*V["pprl"]./V["bsq"]
        V["betaprp"] = 2*V["pprp"]./V["bsq"]
        V["betaprl"] = 2*V["pprl"]./V["bsq"]
    end

    return V

end

function readHST(s::String)
    # fulldata = readdlm(s, '  ', Float64, '\n', header=false, skipstart=0)
    io = open(s)
    readline(io) # First comment
    fullfile = IOBuffer(read(io, String)[2:end]) # Remove comment from first line

    fulldata = readtable(fullfile, separator=' ', skipstart=0)
    println(describe(fulldata))

    return fulldata
end
