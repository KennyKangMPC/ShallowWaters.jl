"""Calculates the 2nd order centred gradient in x-direction on any grid (u,v,T or q).
The size of dudx must be m-1,n compared to m,n = size(u)"""
function ∂x!(dudx::Array{T,2},u::Array{T,2}) where {T<:AbstractFloat}
    m,n = size(dudx)
    @boundscheck (m+1,n) == size(u) || throw(BoundsError())

    #TODO @simd?
    @inbounds for j ∈ 1:n
        for i ∈ 1:m
            dudx[i,j] = u[i+1,j] - u[i,j]
        end
    end
end

"""Calculates the 2nd order centred gradient in y-direction on any grid (u,v,T or q).
The size of dudy must be m,n-1 compared to m,n = size(u)."""
function ∂y!(dudy::Array{T,2},u::Array{T,2}) where {T<:AbstractFloat}
    m,n = size(dudy)
    @boundscheck (m,n+1) == size(u) || throw(BoundsError())

    #TODO @simd?
    @inbounds for j ∈ 1:n
        for i ∈ 1:m
            dudy[i,j] = u[i,j+1] - u[i,j]
        end
    end
end

""" ∇² is the 2nd order centred Laplace-operator ∂/∂x^2 + ∂/∂y^2.
The 1/Δ²-factor is omitted and moved into the viscosity coefficient."""
function ∇²!(du::Array{T,2},u::Array{T,2}) where {T<:AbstractFloat}
    m, n = size(du)
    @boundscheck (m+2,n+2) == size(u) || throw(BoundsError())

    #TODO @simd?
    @inbounds for i ∈ 1:n
        for j ∈ 1:m
            du[j,i] = minus_4*u[j+1,i+1] + u[j,i+1] + u[j+2,i+1] + u[j+1,i] + u[j+1,i+2]
        end
    end
end
