# define constants
const Numtype = Float64
#const Numtype = Posit{16,0}
#const Numtype = Main.FiniteFloats.Finite16
#const Numtype = BigFloat
#setprecision(7)

const nx = 100                  # number of grid cells in x-direction
const Lx = 2000e3               # length of the domain in x-direction
const L_ratio = 2               # Domain aspect ratio of Lx/Ly

const gravity = 10.             # gravitational acceleration
const water_depth = 500.        # layer thickness at rest
const ρ = 1e3                   # density

const wind_forcing = "channel"  # "channel", "double_gyre", "shear" or "none"
const Fx0 = 0.12                # wind stress strength [Pa], default 0.12

const topography_feature = "ridge"
const topofeat_height = 50.      # height of seamount
const topofeat_width = 300e3    # horizontal scale [m] of the seamount

const surface_forcing = false   # or true
const t_relax = 5.              # time scale of the interface_relaxation [days]
const η_refh = 5.               # height difference [m] of the interface relaxation profile
const η_refw = 50e3             # width [m] of the tangent used for the interface relaxation

const cfl = 1.0                 # CFL number
const Ndays = 100               # number of days to integrate for

# boundary condtions
const bc_x = "periodic"         # "periodic" or anything else for nonperiodic
const lbc = 1.                  # lateral boundary condition parameter
                                # 0 free-slip, 0<lbc<2 partial-slip, 2 no-slip

const adv_scheme = "ArakawaHsu"   # "Sadourny" or "ArakawaHsu"

const bottom_friction = "linear" # "linear" or "quadratic"
const drag = 1e-5               # bottom drag coefficient [dimensionless] for quadratic
const τdrag = 300.               # bottom drag coefficient [days] for linear

const diffusion = "Constant"    # "Smagorinsky" or "Constant", biharmonic in both cases
const ν_const = 500             # [m^2/s] scaling constant for Constant biharmonic diffusion
const c_smag = 0.15             # Smagorinsky coefficient [dimensionless]

const Uadv = 5                  # Velocity scale [m/s] for tracer advection

const output = 1                # 1 for nc output 0 for none
const output_vars = ["eta"]
const output_dt = 6             # output time step in hours
#const outpath = "/network/aopp/cirrus/pred/kloewer/julsdata/forecast2/Float64/"
const outpath = "/network/aopp/chaos/pred/kloewer/forecast2/Float64Sad/"

const initial_cond = "ncfile"   # "rest" or "ncfile"
#const initpath = "/network/aopp/cirrus/pred/kloewer/julsdata/forecast2/"
const initpath = "/network/aopp/chaos/pred/kloewer/forecast2/"

const init_run_id = 1           # only for starting from ncfile

const ϕ = 30.                   # central latitue of the domain
