# NUMBER FORMAT OPTIONS
const Numtype = Float32
#const Numtype = Posit{16,2}
#const Numtype = Main.FiniteFloats.Finite16
#const Numtype = BigFloat
#setprecision(7)

# DOMAIN RESOLUTION AND RATIO
const nx = 100                      # number of grid cells in x-direction
const Lx = 1000e3                   # length of the domain in x-direction
const L_ratio = 1                   # Domain aspect ratio of Lx/Ly

# PHYSICAL CONSTANTS
const gravity = 10.                 # gravitational acceleration
const water_depth = 500.            # layer thickness at rest
const ρ = 1e3                       # density
const ϕ = 15.                       # central latitue of the domain (for coriolis)
const ω = 2π/(24*3600)              # Earth's angular frequency [s^-1]
const R = 6.371e6                   # Earth's radius [m]

# WIND FORCING OPTIONS
const wind_forcing_x = "double_gyre"# "channel", "double_gyre", "shear","constant" or "none"
const wind_forcing_y = "constant"   # "channel", "double_gyre", "shear","constant" or "none"
const Fx0 = 0.12                    # wind stress strength [Pa], default 0.12
const Fy0 = 0.0

# BOTTOM TOPOGRAPHY OPTIONS
const topography_feature = "flat"   # "ridge", "seamount", "flat", "ridges", "bathtub"
const topofeat_height = 10.         # height of seamount
const topofeat_width = 300e3        # horizontal scale [m] of the seamount

# SURFACE RELAXATION
const surface_relax = false         # boolean
const t_relax = 100.                # time scale of the interface_relaxation [days]
const η_refh = 5.                   # height difference [m] of the interface relaxation profile
const η_refw = 100e3                # width [m] of the tangent used for the interface relaxation

# SURFACE FORCING
const surface_forcing = false       # boolean
const ωyr = 1.0                     # (annual) frequency [1/year]
const A₀ = 3e-5                     # Amplitude [m/s]

# TIME STEPPING OPTIONS
const RKo = 4                       # Order of the RK time stepping scheme (3 or 4)
const cfl = 1.0                     # CFL number (1.0 recommended for RK4, 0.6 for RK3)
const Ndays = 100                   # number of days to integrate for
const nstep_diff = 1                # diffusive part every nstep_diff time steps.
const nstep_advcor = 0              # advection and coriolis update every nstep_advcor time steps.
                                    # 0 means it is included in every RK4 substep

# BOUNDARY CONDITION OPTIONS
const bc_x = "nonperiodic"          # "periodic" or anything else for nonperiodic
const lbc = 2.                      # lateral boundary condition parameter
                                    # 0 free-slip, 0<lbc<2 partial-slip, 2 no-slip

# MOMENTUM ADVECTION OPTIONS
const adv_scheme = "Sadourny"       # "Sadourny" or "ArakawaHsu"
const dynamics = "nonlinear"        # "linear" or "nonlinear"

# BOTTOM FRICTION OPTIONS
const bottom_friction = "none"      # "linear", "quadratic" or "none"
const drag = 1e-5                   # bottom drag coefficient [dimensionless] for quadratic
const τdrag = 300.                  # bottom drag coefficient [days] for linear

# DIFFUSION OPTIONS
const diffusion = "Constant"     # "Smagorinsky" or "Constant", biharmonic in both cases
const ν_const = 500.0               # [m^2/s] scaling constant for Constant biharmonic diffusion
const c_smag = 0.15                 # Smagorinsky coefficient [dimensionless]

# TRACER ADVECTION
const tracer_advection = true       # "true" or "false"
const tracer_relaxation = true      # "true" or "false"
const tracer_consumption = true     # "true" or "false"
const tracer_pumping = true
const injection_region = "rect"     # "west", "south", "rect" or flat
const sst_initial = "flat"          # same here
const sstrestart = true            # start from previous sst file
const Uadv = 0.15                    # Velocity scale [m/s] for tracer advection
const SSTmax = 1.                   # tracer (sea surface temperature) max for restoring
const SSTmin = 0.                   # tracer (sea surface temperature) min for restoring
const τSST = 500.                   # tracer restoring time scale [days]
const jSST = 50*365.                # tracer consumption [days]
const SST_λ0 = 222e3                # [m] transition position of relaxation timescale
const SST_λs = 111e3                # [m] transition width of relaxation timescale
const SST_γ0 = 8.35                 # [days] injection time scale
const SSTw = 1000e3                 # width [m] of the tangent used for the IC and interface relaxation
const SSTϕ = 0.01                   # latitude/longitude ∈ [0,1] of sst edge

# OUTPUT OPTIONS
const output = true                 # for nc output
const output_tend = false           # ouput for tendencies as well?
const output_diagn = false          # output diagnostic variables as well?
const output_progn_vars = ["sst"]   #["u","v","eta","sst"]
const output_tend_vars = ["du","dv","deta","Bu","Bv","LLu1","LLu2","LLv1","LLv2",
                            "qhv","qhu","dpdx","dpdy","dUdx","dVdy"]
#const output_tend_vars = ["qhv","qhu","dpdx","dpdy","dUdx","dVdy"]
const output_diagn_vars = ["q"]#,"q","p","dudx","dvdy","dudy","dvdx","Lu","Lv","xd","yd"]

const output_dt = 6                 # output time step in hours
#const outpath = "/network/aopp/chaos/pred/kloewer/julsdata/eike/"
const outpath = "/Users/milan/phd/tests/"

# INITIAL CONDITIONS
const initial_cond = "rest"         # "rest" or "ncfile"
const initpath = "/network/aopp/chaos/pred/kloewer/julsdata/eike/"

const init_run_id = 0               # only for starting from ncfile
