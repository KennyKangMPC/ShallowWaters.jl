#function TimeIntegration(u,v,η,sst)
function TimeIntegration!(  ::Type{T},
                            P::Parameter,
                            G::Grid,
                            C::Constants,
                            Prog::PrognosticVars,
                            Diag::DiagnosticVars) where {T<:AbstractFloat}

    # FORCING
    # Fx = windx()
    # Fy = windy()
    # f_u,f_v,f_q = coriolis_parameter()
    # H = topography()
    # η_ref = interface_relaxation()
    # Fη = kelvin_pump(x_T,y_T)
    # sst_ref = sst_inj_region()
    # SSTγ = sst_γ(x_T,y_T)

    F = Forcing{T}(P,G)

    # add halo with ghost point copy
    u,v,η,sst = add_halo(u,v,η,sst)

    # PREALLOCATE
    du,u0,u1,dudx,dudy,u_v = preallocate_u_vars()
    dv,v0,v1,dvdx,dvdy,v_u = preallocate_v_vars()
    dη,η0,η1,h = preallocate_η_vars()
    h_u,U,h_v,V,dUdx,dVdy = preallocate_continuity(H)
    h_q,q,q_v,qhu,U_v,q_u,qhv,V_u = preallocate_Sadourny()
    qα,qβ,qγ,qδ = preallocate_ArakawaHsu()
    u²,v²,KEu,KEv,p,dpdx,dpdy = preallocate_Bernoulli()
    sqrtKE,sqrtKE_u,sqrtKE_v,Bu,Bv = preallocate_bottomdrag()
    Lu,Lv,dLudx,dLudy,dLvdx,dLvdy = preallocate_Laplace()
    DT,DS,DS_q,νSmag,νSmag_q,S11,S12,S21,S22,LLu1,LLu2,LLv1,LLv2 = preallocate_Smagorinsky()
    xd,yd,um,vm,u_T,um_T,v_T,vm_T,uinterp,vinterp,ssti = preallocate_semiLagrange()

    # if dynamics == "linear"
    #     # layer thickness
    #     Ix!(h_u,H)
    #     Iy!(h_v,H)
    # end

    # propagate initial conditions
    u0 .= u
    v0 .= v
    η0 .= η

    # feedback and output
    t0,progrtxt = feedback_ini()
    ncs_progn,ncs_tend,ncs_diagn,iout = output_ini(u,v,η,sst,du,dv,dη,qhv,qhu,dpdx,dpdy,dUdx,dVdy,Bu,Bv,LLu1,LLu2,LLv1,LLv2,
                                                    q,p,dudx,dvdy,dudy,dvdx,Lu,Lv,xd,yd,f_q)
    nans_detected = false

    t = 0           # model time
    for i = 1:nt

        # ghost point copy for boundary conditions
        ghost_points!(u,v,η)
        u1 .= u
        v1 .= v
        η1 .= η

        # Runge-Kutta 4th order / 3rd order
        for rki = 1:RKo
            if rki > 1
                ghost_points!(u1,v1,η1)
            end

            rhs!(du,dv,dη,u1,v1,η1,Fx,Fy,f_u,f_v,f_q,H,η_ref,Fη,t,
                dvdx,dudy,dpdx,dpdy,
                p,u²,v²,KEu,KEv,dUdx,dVdy,
                h,h_u,h_v,h_q,U,V,U_v,V_u,u_v,v_u,
                qhv,qhu,q,q_u,q_v,
                qα,qβ,qγ,qδ)

            if rki < RKo
                caxb!(u1,u,RKb[rki]*Δt,du)  #u1 .= u .+ RKb[rki]*Δt*du
                caxb!(v1,v,RKb[rki]*Δt,dv)  #v1 .= v .+ RKb[rki]*Δt*dv
                caxb!(η1,η,RKb[rki]*Δt,dη)  #η1 .= η .+ RKb[rki]*Δt*dη
            end

            # sum RK-substeps on the go
            axb!(u0,RKa[rki]*Δt,du)  #u0 .+= RKa[rki]*Δt*du
            axb!(v0,RKa[rki]*Δt,dv)  #v0 .+= RKa[rki]*Δt*dv
            axb!(η0,RKa[rki]*Δt,dη)  #η0 .+= RKa[rki]*Δt*dη
        end

        ghost_points!(u0,v0,η0)

        # ADVECTION and CORIOLIS TERMS
        # although included in the tendency of every RK substep,
        # only update every nstep_advcor steps!
        if dynamics == "nonlinear" && nstep_advcor > 0 && (i % nstep_advcor) == 0
            rhs_advcor!(u0,v0,η0,H,h,h_q,dvdx,dudy,u²,v²,KEu,KEv,
                                q,f_q,qhv,qhu,qα,qβ,qγ,qδ,q_u,q_v)
        end

        # DIFFUSIVE TERMS - SEMI-IMPLICIT EULER
        # use u0 = u^(n+1) to evaluate tendencies, add to u0 = u^n + rhs
        if (i % nstep_diff) == 0    # evaluate only every nstep_diff time steps
            bottom_drag!(Bu,Bv,KEu,KEv,sqrtKE,sqrtKE_u,sqrtKE_v,u0,v0,η0,
                H,h,u²,v²,h_u,h_v)
            diffusive!(dudx,dudy,dvdx,dvdy,DS,DS_q,DT,νSmag,νSmag_q,Lu,Lv,
                dLudx,dLudy,dLvdx,dLvdy,S11,S12,S21,S22,
                LLu1,LLu2,LLv1,LLv2,u0,v0)
            add_drag_diff_tendencies!(u0,v0,Bu,Bv,LLu1,LLu2,LLv1,LLv2)
        end

        # RK3/4 copy back from substeps
        u .= u0
        v .= v0
        η .= η0
        t += dtint

        # TRACER ADVECTION
        # mid point (in time) velocity for the advective time step
        if tracer_advection && ((i+nadvstep_half) % nadvstep) == 0
            um .= u
            vm .= v
        end

        if tracer_advection && (i % nadvstep) == 0
            departure!(u,v,u_T,v_T,um,vm,um_T,vm_T,uinterp,vinterp,xd,yd)
            adv_sst!(ssti,sst,xd,yd)
            if tracer_relaxation
                tracer_relax!(ssti,sst_ref,SSTγ)
            end
            if tracer_consumption
                tracer_consumption!(ssti)
            end
            ghost_points_sst!(ssti)
            sst .= ssti

            # conserved?
            #println(mean(sst[halosstx+1:end-halosstx,halossty+1:end-halossty].*h[haloη+1:end-haloη,haloη+1:end-haloη]))
        end

        # feedback and output
        t0,nans_detected = feedback(u,v,η,sst,i,t0,nt,nans_detected,progrtxt)

        ncs_diagn = output_diagn_nc(ncs_diagn,i,iout,q,p,dudx,dvdy,dudy,dvdx,Lu,Lv,xd,yd,f_q)
        ncs_tend = output_tend_nc(ncs_tend,i,iout,du,dv,dη,qhv,qhu,dpdx,dpdy,dUdx,dVdy,Bu,Bv,LLu1,LLu2,LLv1,LLv2)
        ncs_progn,iout = output_progn_nc(ncs_progn,i,iout,u,v,η,sst)

        if nans_detected
            break
            #TODO break all MPI processes
        end
    end

    # finalise feeback and output
    feedback_end(progrtxt,t0)
    output_close(ncs_progn,ncs_tend,ncs_diagn,progrtxt)

    return u,v,η,sst
end

"""Add to a x multiplied with b. a += x*b """
function axb!(a::Array{T,2},x::T,b::Array{T,2}) where {T<:AbstractFloat}
    m,n = size(a)
    @boundscheck (m,n) == size(b) || throw(BoundsError())

    #TODO @simd?
    @inbounds for j ∈ 1:n
        for i ∈ 1:m
           a[i,j] += x*b[i,j]
        end
    end
end

"""c equals add a to x multiplied with b. c = a + x*b """
function caxb!(c::Array{T,2},a::Array{T,2},x::T,b::Array{T,2}) where {T<:AbstractFloat}
    m,n = size(a)
    @boundscheck (m,n) == size(b) || throw(BoundsError())
    @boundscheck (m,n) == size(c) || throw(BoundsError())

    #TODO @simd?
    @inbounds for j ∈ 1:n
        for i ∈ 1:m
           c[i,j] = a[i,j] + x*b[i,j]
        end
    end
end
