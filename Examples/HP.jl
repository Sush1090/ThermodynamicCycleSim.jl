

using CoolPropCycles, ModelingToolkit, DifferentialEquations, CoolProp


@independent_variables t
fluid = "R134A"
_system = Isentropic_η(η = 0.8,πc = 4.5) # fix the isentropic Efficiency of compressor and pressre ratio
valve_system  = IsenthalpicExpansionValve(4.5)
start_T = 250; # Temperature at source 
start_p = PropsSI("P","Q",1,"T",start_T,fluid) - 1e2 # pressure at source. For HP we need gas at source
@assert PhaseSI("T",start_T,"P",start_p,fluid) == "gas"
ΔT_superheat = start_T - PropsSI("T","P",start_p,"Q",0,fluid) ; # ensure the superheat temperature to reach bck to starting state.
start_h = PropsSI("H","T",start_T,"P",start_p,fluid); start_mdot = 0.2 #kg/s


@named source = MassSource(source_enthalpy = start_h,source_pressure = start_p,source_mdot = start_mdot,fluid = fluid)
@named comp = Compressor(_system, fluid =fluid)
@named cond = SimpleCondensor(ΔT_sc = 1e-2,Δp = [0,0,0],fluid = fluid)
@named exp = Valve(valve_system,fluid= fluid)
@named evap = SimpleEvaporator(ΔT_sh = ΔT_superheat,Δp = [0,0,0],fluid = fluid)
@named sink = MassSink(fluid = fluid)

# Define equations
eqs = [
    connect(source.port,comp.inport)
    connect(comp.outport,cond.inport)
    connect(cond.outport,exp.inport)
    connect(exp.outport,evap.inport)
    connect(evap.outport,sink.port)
]
systems=[source,comp,cond,exp,evap,sink] # Define system

@named HP = ODESystem(eqs, t, systems=systems)

u0 = []
tspan = (0.0, 10.0)
sys = structural_simplify(HP)
prob = ODEProblem(sys,u0,tspan,guesses = [])
sol = solve(prob)

#compute COP
#Note: sign convetion: Power supplied to the system is +ve while from thee system is -ve
@show COP = sol[cond.P][1]/sol[comp.P][1]
#Check if the final state is close to the inital state. 
Compute_cycle_error(sol,systems)
CoolPropCycles.PhasePlot(PhasePlotType_TS(),sol,systems,fluid)