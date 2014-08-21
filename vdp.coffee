f = (t, v, mu) ->
    [v[1], mu*(1-v[0]*v[0])*v[1]-v[0]]
mu = 1 # $\mu$
{rk, ode} = $blab.ode # Import ODE solver
t = linspace 0, 20, 100 #; Time grid
w = ode(rk[1], f, t, [1, 1], mu) #; Solve

plot t, w.T,
    xlabel: "t"
    ylabel: "x, y"
    height: 160
    series:
        shadowSize: 0
        color: "black"
        lines: lineWidth: 1
