"""Initialises netCDF files for data output of the prognostic, tendency and diagnostic variables."""
function output_ini(u,v,η,sst,du,dv,dη,qhv,qhu,dpdx,dpdy,dUdx,dVdy,Bu,Bv,LLu1,LLu2,LLv1,LLv2,
                        q,p,dudx,dvdy,dudy,dvdx,Lu,Lv,xd,yd,f_q)
    # only process with rank 0 defines the netCDF file
    if output #&& prank == 0

        # PROGNOSTIC VARIABLES OUTPUT STRINGS
        all_output_progn_vars = ["u","v","eta","sst"]
        units_progn = ["m/s","m/s","m","degC"]
        longnames_progn = ["zonal velocity","meridional velocity","sea surface height","sea surface temperature"]

        # TENDENCY VARIABLES OUTPUT STRINGS
        all_output_tend_vars = ["du","dv","deta","qhv","qhu","dpdx","dpdy","dUdx","dVdy","Bu","Bv","LLu1","LLu2","LLv1","LLv2"]
        unit1,unit2 = "m^2/s^2","m^2/s"
        units_tend = cat(repeat([unit1],7),repeat([unit2],2),repeat([unit1],6),dims=1)
        longnames_tend = ["u tendency","v tendency","eta tendency",
                    "Advection of PV u-comp.","Advection of PV v-comp.",
                    "Bernoulli potential x-gradient","Bernoulli potential y-gradient",
                    "Volume flux x-gradient","Volume flux y-gradient",
                    "Bottom friction u-comp.","Bottom friction v-comp.",
                            "Diffusion u-comp. 1","Diffusion u-comp. 2",
                            "Diffusion v-comp. 1","Diffusion v-comp. 2"]

        # DIAGNOSTIC VARIABLES OUTPUT STRINGS#
        all_output_diagn_vars = ["q","p","dudx","dvdy","dudy","dvdx","Lu","Lv","xd","yd","relvort"]
        units_diagn = ["1/(ms)","m^2/s^2","m/s","m/s","m/s","m/s","m/s","m/s","1","1","1"]
        longnames_diagn = ["Potential vorticity","Bernoulli potential",
                            "Zonal velocity x-gradient","Meridional velocity y-gradient",
                            "Zonal velocity y-gradient","Meridional velocity x-gradient",
                            "Laplace of u velocity", "Laplace of v velocity",
                            "Relative departure point x","Relative departure point y",
                            "Relative vorticity"]

        # collect all grids for easy access per index
        allx = (x_u,x_v,x_T,x_q_halo[3:end-2+ep])
        ally = (y_u,y_v,y_T,y_q)
        grids_progn = [1,2,3,3]           # for easy access per index
        grids_tend = [1,2,3,1,2,1,2,3,3,1,2,1,1,2,2]
        grids_diagn = [4,3,3,3,4,4,1,2,3,3,4]

        ncs_progn = Array{Any,1}(zeros(Int,length(all_output_progn_vars)))
        ncs_tend = Array{Any,1}(zeros(Int,length(all_output_tend_vars)))
        ncs_diagn = Array{Any,1}(zeros(Int,length(all_output_diagn_vars)))

        # loop over all outputtable variables
        # PROGNOSTIC VARIABLES
        for (ivarout,outvar) in enumerate(all_output_progn_vars)
            if outvar in output_progn_vars    # check whether output is desired (specified in parameters.jl)
                ncs_progn[ivarout] = nccreate(allx[grids_progn[ivarout]],ally[grids_progn[ivarout]],
                                outvar,runpath,units_progn[ivarout],longnames_progn[ivarout])
            end
        end

        # TENDENCY VARIABLES
        if output_tend
            for (ivarout,outvar) in enumerate(all_output_tend_vars)
                if outvar in output_tend_vars    # check whether output is desired (specified in parameters.jl)
                    ncs_tend[ivarout] = nccreate(allx[grids_tend[ivarout]],ally[grids_tend[ivarout]],
                                    outvar,runpath,units_tend[ivarout],longnames_tend[ivarout])
                end
            end
        end

        # DIAGNOSTIC VARIABLES
        if output_diagn
            for (ivarout,outvar) in enumerate(all_output_diagn_vars)
                if outvar in output_diagn_vars    # check whether output is desired (specified in parameters.jl)
                    ncs_diagn[ivarout] = nccreate(allx[grids_diagn[ivarout]],ally[grids_diagn[ivarout]],
                                    outvar,runpath,units_diagn[ivarout],longnames_diagn[ivarout])
                end
            end
        end

        # Write attributes and units for dimensions
        Dictu = output_dict()

        for nc in cat(ncs_progn,ncs_tend,ncs_diagn,dims=1)
            if nc != 0
                NetCDF.putatt(nc,"global",Dictu)
                NetCDF.putatt(nc,"t",Dict("units"=>"s","long_name"=>"time"))
                NetCDF.putatt(nc,"x",Dict("units"=>"m","long_name"=>"zonal coordinate"))
                NetCDF.putatt(nc,"y",Dict("units"=>"m","long_name"=>"meridional coordinate"))
            end
        end

        # write initial conditions
        iout = 1   # counter for output time steps
        ncs_diag = output_diagn_nc(ncs_diagn,0,iout,q,p,dudx,dvdy,dudy,dvdx,Lu,Lv,xd,yd,f_q)
        ncs_tend = output_tend_nc(ncs_tend,0,iout,du,dv,dη,qhv,qhu,dpdx,dpdy,dUdx,dVdy,Bu,Bv,LLu1,LLu2,LLv1,LLv2)
        ncs_progn,iout = output_progn_nc(ncs_progn,0,iout,u,v,η,sst)

        # also output scripts
        scripts_output()

        return ncs_progn,ncs_tend,ncs_diagn,iout
    else
        return nothing,nothing,nothing,nothing
    end
end

function nccreate(x::Array{Float64,1},y::Array{Float64,1},name::String,path::String,unit::String,long_name::String)
    xdim = NcDim("x",length(x),values=x)
    ydim = NcDim("y",length(y),values=y)
    tdim = NcDim("t",0,unlimited=true)

    var = NcVar(name,[xdim,ydim,tdim],t=Float32)
    tvar = NcVar("t",tdim,t=Int32)

    nc = NetCDF.create(path*name*".nc",[var,tvar],mode=NC_NETCDF4)
    NetCDF.putatt(nc,name,Dict("units"=>unit,"long_name"=>long_name))
    return nc
end

"""Writes prognostic variables to pre-initialised netCDF files."""
function output_progn_nc(ncs,i,iout,u,v,η,sst)

    # if nprocs > 1
    #     #TODO MPI Gather data
    #     #TODO rename u,v,η necessary? To distinguish between the loval u,v,η and the gathered u,v,η?
    # end

    # output only every nout time steps
    # only process 0 will do the output
    if i % nout == 0 && output #&& prank == 0

        # cut off the halo
        if ncs[1] != 0
            NetCDF.putvar(ncs[1],"u",Float32.(u[halo+1:end-halo,halo+1:end-halo]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[2] != 0
            NetCDF.putvar(ncs[2],"v",Float32.(v[halo+1:end-halo,halo+1:end-halo]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[3] != 0
            NetCDF.putvar(ncs[3],"eta",Float32.(η[haloη+1:end-haloη,haloη+1:end-haloη]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[4] != 0
            NetCDF.putvar(ncs[4],"sst",Float32.(sst[halosstx+1:end-halosstx,halossty+1:end-halossty]),start=[1,1,iout],count=[-1,-1,1])
        end

        for nc in ncs
            if nc !=0
                #TODO check whether Int64 here clashes with the Int32 of type of time dimension
                NetCDF.putvar(nc,"t",Int64[i*dtint],start=[iout])
                NetCDF.sync(nc)     # sync to view netcdf while model is still running
            end
        end

        iout += 1
    end

    #TODO MPI Barrier, Waitall?

    return ncs,iout
end

""" Writes tendency variables to pre-initialised netCDF files."""
function output_tend_nc(ncs,i,iout,du,dv,dη,qhv,qhu,dpdx,dpdy,dUdx,dVdy,Bu,Bv,LLu1,LLu2,LLv1,LLv2)
    if i % nout == 0 && output && output_tend #&& prank == 0

        # cut off the halo
        if ncs[1] != 0
            NetCDF.putvar(ncs[1],"du",Float32.(du[halo+1:end-halo,halo+1:end-halo]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[2] != 0
            NetCDF.putvar(ncs[2],"dv",Float32.(dv[halo+1:end-halo,halo+1:end-halo]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[3] != 0
            NetCDF.putvar(ncs[3],"deta",Float32.(dη[haloη+1:end-haloη,haloη+1:end-haloη]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[4] != 0
            NetCDF.putvar(ncs[4],"qhv",Float32.(qhv),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[5] != 0
            NetCDF.putvar(ncs[5],"qhu",Float32.(qhu),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[6] != 0
            NetCDF.putvar(ncs[6],"dpdx",Float32.(dpdx[2-ep:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[7] != 0
            NetCDF.putvar(ncs[7],"dpdy",Float32.(dpdy[2:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[8] != 0
            NetCDF.putvar(ncs[8],"dUdx",Float32.(dUdx[:,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[9] != 0
            NetCDF.putvar(ncs[9],"dVdy",Float32.(dVdy[2:end-1,:]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[10] != 0
            NetCDF.putvar(ncs[10],"Bu",Float32.(Bu[2-ep:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[11] != 0
            NetCDF.putvar(ncs[11],"Bv",Float32.(Bv[2:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[12] != 0
            NetCDF.putvar(ncs[12],"LLu1",Float32.(LLu1[:,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[13] != 0
            NetCDF.putvar(ncs[13],"LLu2",Float32.(LLu2[2-ep:end,:]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[14] != 0
            NetCDF.putvar(ncs[14],"LLv1",Float32.(LLv1[:,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[15] != 0
            NetCDF.putvar(ncs[15],"LLv2",Float32.(LLv2[2:end-1,:]),start=[1,1,iout],count=[-1,-1,1])
        end

        for nc in ncs
            if nc !=0
                #TODO check whether Int64 here clashes with the Int32 of type of time dimension
                NetCDF.putvar(nc,"t",Int64[i*dtint],start=[iout])
                NetCDF.sync(nc)     # sync to view netcdf while model is still running
            end
        end
    end

    #TODO MPI Barrier, Waitall?

    return ncs
end

""" Writes data to a netCDF file."""
function output_diagn_nc(ncs,i,iout,q,p,dudx,dvdy,dudy,dvdx,Lu,Lv,xd,yd,f_q)
    if i % nout == 0 && output && output_diagn #&& prank == 0

        # cut off the halo
        if ncs[1] != 0
            #TODO for periodic BC q[1,:] = q[end,:] avoid this redundant output?
            NetCDF.putvar(ncs[1],"q",Float32.(q)/Δ,start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[2] != 0
            NetCDF.putvar(ncs[2],"p",Float32.(p[2:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[3] != 0
            NetCDF.putvar(ncs[3],"dudx",Float32.(dudx[2+ep:end-1,3:end-2]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[4] != 0
            NetCDF.putvar(ncs[4],"dvdy",Float32.(dvdy[3:end-2,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[5] != 0
            NetCDF.putvar(ncs[5],"dudy",Float32.(dudy[2+ep:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[6] != 0
            NetCDF.putvar(ncs[6],"dvdx",Float32.(dvdx[2:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[7] != 0
            NetCDF.putvar(ncs[7],"Lu",Float32.(Lu[2:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[8] != 0
            NetCDF.putvar(ncs[8],"Lv",Float32.(Lv[2:end-1,2:end-1]),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[9] != 0
            NetCDF.putvar(ncs[9],"xd",Float32.(xd),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[10] != 0
            NetCDF.putvar(ncs[10],"yd",Float32.(yd),start=[1,1,iout],count=[-1,-1,1])
        end
        if ncs[11] != 0
            #TODO for periodic BC relvort[1,:] = relvort[end,:] avoid this redundant output?
            NetCDF.putvar(ncs[11],"relvort",Float32.((dvdx[2:end-1,2:end-1]-dudy[2+ep:end-1,2:end-1])./abs.(f_q)),start=[1,1,iout],count=[-1,-1,1])
        end


        for nc in ncs
            if nc !=0
                #TODO check whether Int64 here clashes with the Int32 of type of time dimension
                NetCDF.putvar(nc,"t",Int64[i*dtint],start=[iout])
                NetCDF.sync(nc)     # sync to view netcdf while model is still running
            end
        end
    end

    #TODO MPI Barrier, Waitall?

    return ncs
end

"""Closes netCDF and progress.txt files."""
function output_close(ncs_progn,ncs_tend,ncs_diagn,progrtxt)
    if output #&& prank == 0
        for nc in cat(ncs_progn,ncs_tend,ncs_diagn,dims=1)
            if nc !=0
                NetCDF.close(nc)
            end
        end
        println("All data stored.")
        write(progrtxt,"All data stored.")
        close(progrtxt)
    end
end

"""Checks output folders to determine a 4-digit run id number."""
function get_run_id_path(order="continue",run_id=nothing)

    """Finds the first gap in a list of integers."""
    function gap(a::Array{Int,1})
        try
            return minimum([i for i in minimum(a):maximum(a) if ~(i in a)])
        catch
            return maximum(a)+1
        end
    end

    # only process rank 0 checks existing folders
    if output #&& prank == 0
        runlist = filter(x->startswith(x,"run"),readdir(outpath))
        existing_runs = [parse(Int,id[4:end]) for id in runlist]
        if length(existing_runs) == 0           # if no runfolder exists yet
            runpath = outpath*"run0000/"
            mkdir(runpath)
            return 0,runpath
        else                                    # create next folder
            if order == "fill"  # find the smallest gap in runfolders
                run_id = gap(existing_runs)
                runpath = outpath*"run"*@sprintf("%04d",run_id)*"/"
                mkdir(runpath)

            elseif order == "specific" # specify the run_id as input argument
                runpath = outpath*"run"*@sprintf("%04d",run_id)*"/"
                try # create folder if not existent
                    mkdir(runpath)
                catch # else rm folder and create new one
                    rm(runpath,recursive=true)
                    mkdir(runpath)
                end

            elseif order == "continue" # find largest folder and count one up
                run_id = maximum(existing_runs)+1
                runpath = outpath*"run"*@sprintf("%04d",run_id)*"/"
                mkdir(runpath)
            else
                throw(error("Order $order is not valid for get_run_id_path(), chose continue, specific or fill."))
            end
            return run_id,runpath
        end
    else
        return 0,"no runpath"
    end
end

#TODO in ensemble mode, the .jl files might have changed since the start and do not correspond to what
#TODO is actually executed!
"""Archives all .jl files of juls in the output folder to make runs reproducible."""
function scripts_output()
    if output #&& prank == 0
        # copy all files in juls main folder
        mkdir(runpath*"scripts")
        for juliafile in filter(x->endswith(x,".jl"),readdir())
            cp(juliafile,runpath*"scripts/"*juliafile)
        end

        # and also in the src folder
        mkdir(runpath*"scripts/src")
        for juliafile in filter(x->endswith(x,".jl"),readdir("src"))
            cp("src/"*juliafile,runpath*"scripts/src/"*juliafile)
        end
    end
end

"""Creates a dictionary with many parameter constants to be included in the nc files."""
function output_dict()
    # Attributes for nc
    Dictu = Dict{String,Any}("description"=>"Data from shallow-water model juls.")
    Dictu["details"] = "Cartesian coordinates, f or beta-plane, Arakawa C-grid"
    Dictu["reference"] = "github.com/milankl/juls"

    Dictu["nx"] = nx
    Dictu["Lx"] = Lx
    Dictu["L_ratio"] = L_ratio
    Dictu["delta"] = Δ

    Dictu["halo"] = halo
    Dictu["haloeta"] = haloη
    Dictu["halosstx"] = halosstx
    Dictu["halossty"] = halossty

    Dictu["g"] = gravity
    Dictu["water_depth"] = water_depth
    Dictu["phi"] = ϕ
    Dictu["density"] = ρ

    Dictu["wind_forcing_x"] = wind_forcing_x
    Dictu["wind_forcing_y"] = wind_forcing_y
    Dictu["Fx0"] = Fx0
    Dictu["Fy0"] = Fy0

    Dictu["topography_feature"] = topography_feature
    Dictu["topofeat_height"] = topofeat_height
    Dictu["topofeat_width"] = topofeat_width

    Dictu["surface_forcing"] = string(surface_forcing)
    Dictu["t_relax"] = t_relax
    Dictu["eta_refh"] = η_refh
    Dictu["η_refw"] = η_refw

    Dictu["Numtype"] = string(Numtype)
    Dictu["output_dt"] = output_dt
    Dictu["nout"] = nout
    Dictu["nadvstep"] = nadvstep
    Dictu["nstep_diff"] = nstep_diff
    Dictu["nstep_advcor"] = nstep_advcor

    Dictu["RKo"] = RKo
    Dictu["cfl"] = cfl
    Dictu["Ndays"] = Ndays

    Dictu["bc_x"] = bc_x
    Dictu["lbc"] = lbc

    Dictu["adv_scheme"] = adv_scheme
    Dictu["dynamics"] = dynamics

    Dictu["bottom_friction"] = bottom_friction
    Dictu["drag"] = drag
    Dictu["taudrag"] = τdrag

    Dictu["diffusion"] = diffusion
    Dictu["nuConst"] = ν_const
    Dictu["c_smag"] = c_smag

    Dictu["tracer_advcetion"] = string(tracer_advection)
    Dictu["tracer_relaxation"] = string(tracer_relaxation)
    Dictu["injection_region"] = injection_region
    Dictu["sstrestart"] = string(sstrestart)
    Dictu["Uadv"] = Uadv
    Dictu["SSTmax"] = SSTmax
    Dictu["SSTmin"] = SSTmin
    Dictu["tauSST"] = τSST
    Dictu["SSTw"] = SSTw
    Dictu["SSTphi"] = SSTϕ

    Dictu["initial_cond"] = initial_cond
    Dictu["init_run_id"] = init_run_id
    Dictu["initpath"] = initpath

    return Dictu
end
