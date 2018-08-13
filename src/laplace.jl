function ∇²!(du::AbstractMatrix,u::AbstractMatrix)
    #= ∇² is the Laplace-operator ∂/∂x^2 + ∂/∂y^2.
    The 1/Δ²-factor is omitted and moved into the viscosity coefficient. =#

    m, n = size(du)
    @boundscheck (m+2,n+2) == size(u) || throw(BoundsError())

    @inbounds for i ∈ 1:n
        for j ∈ 1:m
            du[j,i] = minus_4*u[j+1,i+1] + u[j,i+1] + u[j+2,i+1] + u[j+1,i] + u[j+1,i+2]
        end
    end
end
