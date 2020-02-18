[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://img.shields.io/badge/repo_status-active-brightgreen?style=flat-square)](https://www.repostatus.org/#active)
[![Travis](https://img.shields.io/travis/com/milankl/ShallowWaters.jl?label=Linux%20%26%20osx&logo=travis&style=flat-square)](https://travis-ci.com/milankl/ShallowWaters.jl)
[![AppVeyor](https://img.shields.io/appveyor/ci/milankl/ShallowWaters-jl?label=Windows&logo=appveyor&logoColor=white&style=flat-square)](https://ci.appveyor.com/project/milankl/ShallowWaters-jl)
[![Cirrus CI](https://img.shields.io/cirrus/github/milankl/ShallowWaters.jl?label=FreeBSD&logo=cirrus-ci&logoColor=white&style=flat-square)](https://cirrus-ci.com/github/milankl/ShallowWaters.jl)

[![DOI](https://zenodo.org/badge/132787050.svg)](https://zenodo.org/badge/latestdoi/132787050)


# ShallowWaters.jl - A type-flexible 16bit shallow water model
![sst](figs/sst_posit16.png?raw=true "SST")

A shallow water model with a focus on type-flexibility and 16bit number formats. ShallowWaters allows for Float64/32/16, [BigFloat](https://docs.julialang.org/en/v1/base/numbers/#BigFloats-and-BigInts-1)/[ArbFloat](https://github.com/JeffreySarnoff/ArbNumerics.jl)/[DoubleFloats](https://github.com/JuliaMath/DoubleFloats.jl), [Posit32/16/8](https://github.com/milankl/SoftPosit.jl), [BFloat16](https://github.com/JuliaComputing/BFloat16s.jl), [Sonum16](https://github.com/milankl/Sonums.jl) and in general every number format with arithmetics and conversions implemented. ShallowWaters also allows for mixed-precision and reduced precision communication.

ShallowWaters is fully-explicit with an energy and enstrophy conserving advection scheme and a Smagorinsky-like biharmonic diffusion operator. Tracer advection is implemented with a semi-Lagrangian advection scheme. Runge-Kutta 4th-order is used for pressure, advective and Coriolis terms and the continuity equation. Semi-implicit time stepping for diffusion and bottom friction. Boundary conditions are either periodic (only in x direction) or non-periodic super-slip, free-slip, partial-slip, or no-slip. Output via [NetCDF](https://github.com/JuliaGeo/NetCDF.jl).

Please feel free to raise an [issue](https://github.com/milankl/ShallowWaters.jl/issues) if you discover bugs or have an idea how to improve ShallowWaters.

### How to use

`RunModel` initialises the model, preallocates memory and starts the time integration. You find the options and default parameters in `src/DefaultParameters.jl` (or by typing `?Parameter`). 
```julia
help?> Parameter
search: Parameter

  Creates a Parameter struct with following options and default values

  T::DataType=Float32                 # number format
  
  Tprog::DataType=T                   # number format for prognostic variables
  Tcomm::DataType=Tprog               # number format for ghost-point copies
  
  # DOMAIN RESOLUTION AND RATIO
  nx::Int=100                         # number of grid cells in x-direction
  Lx::Real=2000e3                     # length of the domain in x-direction [m]
  L_ratio::Real=2                     # Domain aspect ratio of Lx/Ly
  ...
```
They can be changed with keyword arguments. The number format `T` is defined as the first (but optional) argument of `RunModel(T,...)`
```julia
julia> Prog = RunModel(Float32,Ndays=10,g=10,H=500,Fx0=0.12);
Starting ShallowWaters on Sun, 20 Oct 2019 19:58:25 without output.
100% Integration done in 4.65s.
```
or by creating a Parameter struct
```julia
julia> P = Parameter(bc="nonperiodic",wind_forcing_x="double_gyre",L_ratio=1,nx=128);
julia> Prog = RunModel(P);
```
The number formats can be different (aka mixed-precision) for different parts of the model. `Tprog` is the number type for the prognostic variables, `Tcomm` is used for communication of boundary values.

### (Some) Features

- Interpolation of initial conditions from low resolution / high resolution runs.
- Output of relative vorticity, potential vorticity and tendencies du,dv,deta
- (Pretty accurate) duration estimate
- Can be run in ensemble mode with ordered non-conflicting output files
- Runs at CFL=1
- Solving the tracer advection comes at basically no cost, thanks to semi-Lagrangian advection scheme
- Also outputs the gradient operators ∂/∂x,∂/∂y and interpolations Ix, Iy for easier post-processing.

### Installation

ShallowWaters.jl is a registered package, so simply do

```julia
julia> ] add ShallowWaters
```

## The equations

The non-linear shallow water model plus tracer equation is

          ∂u/∂t + (u⃗⋅∇)u - f*v = -g*∂η/∂x - c_D*|u⃗|*u + ∇⋅ν*∇(∇²u) + Fx(x,y)     (1)
          ∂v/∂t + (u⃗⋅∇)v + f*u = -g*∂η/∂y - c_D*|u⃗|*v + ∇⋅ν*∇(∇²v) + Fy(x,y)     (2)
          ∂η/∂t = -∇⋅(u⃗h) + γ*(η_ref - η) + Fηt(t)*Fη(x,y)                       (3)
          ∂ϕ/∂t = -u⃗⋅∇ϕ                                                          (4)

with the prognostic variables velocity u⃗ = (u,v) and sea surface heigth η. The layer thickness is h = η + H(x,y). The Coriolis parameter is f = f₀ + βy with beta-plane approximation. The graviational acceleration is g. Bottom friction is either quadratic with drag coefficient c_D or linear with inverse time scale r. Diffusion is realized with a biharmonic diffusion operator, with either a constant viscosity coefficient ν, or a Smagorinsky-like coefficient that scales as ν = c_Smag*|D|, with deformation rate |D| = √((∂u/∂x - ∂v/∂y)² + (∂u/∂y + ∂v/∂x)²). Wind forcing Fx is constant in time, but may vary in space.

The linear shallow water model equivalent is

          ∂u/∂t - f*v = -g*∂η/∂x - r*u + ∇⋅ν*∇(∇²u) + Fx(x,y)     (1)
          ∂v/∂t + f*u = -g*∂η/∂y - r*v + ∇⋅ν*∇(∇²v) + Fy(x,y)     (2)
          ∂η/∂t = -H*∇⋅u⃗ + γ*(η_ref - η) + Fηt(t)*Fη(x,y)         (3)
          ∂ϕ/∂t = -u⃗⋅∇ϕ                                           (4)

ShallowWaters.jl discretises the equation on an equi-distant Arakawa C-grid, with 2nd order finite-difference operators. Boundary conditions are implemented via a ghost-point copy and each variable has a halo of variable size to account for different stencil sizes of various operators.

ShallowWaters.jl splits the time steps for various terms: Runge Kutta 4th order scheme for the fast varying terms. The diffusive terms (bottom friction and diffusion) are solved semi-implicitly every n-th time step. The tracer equation is solved with a semi-Lagrangian scheme that uses much larger time steps.
