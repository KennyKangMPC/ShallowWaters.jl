function time_integration(u,v,η)

    # FORCING
    Fx = wind()
    f_q = beta_plane()
    H = topography()
    η_ref = interface_relaxation()

    # add halo with ghost point copy
    u,v,η = add_halo(u,v,η)

    # PREALLOCATE
    du,u0,u1,dudx,dudy = preallocate_u_vars()
    dv,v0,v1,dvdx,dvdy = preallocate_v_vars()
    dη,η0,η1,h = preallocate_η_vars()
    h_u,U,h_v,V,dUdx,dVdy = preallocate_continuity()
    h_q,q,q_v,qhu,U_v,q_u,qhv,V_u = preallocate_Sadourny()
    qα,qβ,qγ,qδ = preallocate_ArakawaHsu()
    u²,v²,KEu,KEv,p,dpdx,dpdy = preallocate_Bernoulli()
    sqrtKE,sqrtKE_u,sqrtKE_v,Bu,Bv = preallocate_bottomdrag()
    Lu,Lv,dLudx,dLudy,dLvdx,dLvdy = preallocate_Laplace()
    DT,DS,DS_q,νSmag,νSmag_q,S11,S12,S21,S22,LLu1,LLu2,LLv1,LLv2 = preallocate_Smagorinsky()

    # propagate initial conditions
    u0 .= u
    v0 .= v
    η0 .= η

    # Runge-Kutta 4th order coefficients
    RKa = Numtype.([1/6,1/3,1/3,1/6])
    RKb = Numtype.([.5,.5,1.])

    # feedback and output
    t0,progrtxt = feedback_ini()
    ncs, iout = output_ini(u,v,η)
    nans_detected = false

    t = 0           # model time
    for i = 1:nt

        # ghost point copy for boundary conditions
        ghost_points!(u,v,η)
        u1 .= u
        v1 .= v
        η1 .= η

        # Runge-Kutta 4th order
        for rki = 1:4
            if rki > 1
                ghost_points!(u1,v1,η1)
            end

            rhs!(du,dv,dη,u1,v1,η1,Fx,f_q,H,η_ref,
                dudx,dvdy,dvdx,dudy,dpdx,dpdy,
                p,u²,v²,KEu,KEv,dUdx,dVdy,
                h,h_u,h_v,h_q,U,V,U_v,V_u,
                qhv,qhu,q,q_u,q_v,
                qα,qβ,qγ,qδ,
                sqrtKE,sqrtKE_u,sqrtKE_v,Bu,Bv,
                DS,DS_q,DT,νSmag,νSmag_q,
                Lu,Lv,dLudx,dLudy,dLvdx,dLvdy,
                S11,S12,S21,S22,
                LLu1,LLu2,LLv1,LLv2)


            if rki < 4
                u1 .= u .+ RKb[rki]*Δt*du
                v1 .= v .+ RKb[rki]*Δt*dv
                η1 .= η .+ RKb[rki]*Δt*dη
            end

            # sum RK-substeps on the go
            u0 .+= RKa[rki]*Δt*du
            v0 .+= RKa[rki]*Δt*dv
            η0 .+= RKa[rki]*Δt*dη
        end

        u .= u0
        v .= v0
        η .= η0
        t += dtint

        # feedback and output
        t0,nans_detected = feedback(u,v,η,i,t0,nt,nans_detected,progrtxt)
        ncs,iout = output_nc(ncs,u,v,η,i,iout)
    end

    # finalise feeback and output
    feedback_end(progrtxt,t0)
    output_close(ncs,progrtxt)

    return u,v,η
end
