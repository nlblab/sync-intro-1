#!vanilla

# Temp fix - to be done in puzlet.js.
Number.prototype.pow = (p) -> Math.pow this, p

WebFontConfig = google:
    families: ["Reenie+Beanie::latin"]

#$("#run_button").prop("disabled", true)

# Global stuff

pi = Math.PI
sin = Math.sin
cos = Math.cos
min = Math.min
COS = (u) -> Math.cos(u*pi/180)
SIN = (u) -> Math.sin(u*pi/180)

repRow = (val, m) -> val for [1..m]

{rk, ode} = $blab.ode # Import ODE solver


# work around unicode issue
char = (id, code) -> $(".#{id}").html "&#{code};"
char "deg", "deg"
char "percent", "#37"
char "equals", "#61"


# Vector field (<a href="http://en.wikipedia.org/wiki/Van_der_Pol_oscillator">Van der Pol</a>)

# VdP equation
f = (t, v, mu) -> 
	[
        v[1]
        mu*(1-v[0]*v[0])*v[1]-v[0]
	]


class Vector

    z = -> new Vector

    constructor: (@x=0, @y=0) ->
        
    add: (v=z()) ->
        @x += v.x
        @y += v.y
        this
    
    mag: () -> Math.sqrt(@x*@x + @y*@y)
        
    ang: () -> Math.atan2(@y, @x)
        
    polar: (m, a) ->
        @x = m*Math.cos(a)
        @y = m*Math.sin(a)
        this

class Figure

    @xMax = 4 # horizontal plot limit
    @yMax = 4 # vertical plot limit

    @margin = {top: 65, right: 65, bottom: 65, left: 65}
    @width = 450 - @margin.left - @margin.top
    @height = 450 - @margin.left - @margin.top


class Canvas

    margin = Figure.margin
    width = Figure.width
    height = Figure.height

    constructor: (id) ->

        @canvas = $(id) 
        #@canvas.css("left","#{margin.left}px").css("top","#{margin.top}px")
        @canvas[0].width = width
        @canvas[0].height = height
        @ctx = @canvas[0].getContext('2d')
        
    clear: -> @ctx.clearRect(0, 0, width, height)

    square: (pos, size, color) ->
        @ctx.fillStyle = color
        @ctx.fillRect(pos.x, pos.y, size, size)


class vfPoint # vector field point

    width  = Figure.width
    height = Figure.height
    
    constructor: (@pos={x:0, y:0}, @mu=1) ->

        @vel = new Vector 0, 0 # velocity
        @vf = new Vector 0, 0 # vector-field coords
        @d = 0 # distance

        @scales() # funcs to X-form between screen position and VF coords
        @update() # VF coords and velocity
        @draw()

    scales: ->
        
        @x = d3.scale.linear()
            .domain([-Figure.xMax, Figure.xMax])
            .range([0, width])
        @y = d3.scale.linear()
            .domain([-Figure.yMax, Figure.yMax])
            .range([height, 0])

    update: ->
        # VF coords
        @vf.x = @x.invert @pos.x
        @vf.y = @y.invert @pos.y
        
        # Velocity (screen units)
        vel = f(0, [@vf.x, @vf.y], @mu)
        @vel.x = @x.invert vel[0]
        @vel.y = @y.invert vel[1]

    draw: ->

    move: ->

        @update()
        
        # Runge Kutta step
        w = ode(rk[1], f, [0, 0.02], [@vf.x, @vf.y], @mu)[1]
        # map VF coords to screen coords
        @pos.x = @x w[0]
        @pos.y = @y w[1]
        
        # accumulate distance (screen units)
        @d += @vel.mag()

    visible: -> # conditions for showing particles
        (0 <= @pos.x <= width) and 
            (0 <= @pos.y <= height) and
            @vel.mag() > 0 and
            @d < 1200
    
class Particle extends vfPoint

    constructor: (@canvas, Z, mu) ->
        super Z, mu

        @size = 2
        @color = ["red", "green", "blue"][Math.floor(3*Math.random())]

    draw: ->
        @canvas.square @pos, @size, @color

            
class Emitter
    
    maxParticles: 500
    rate: 3
    ch: Figure.height
    cw: Figure.width
    
    constructor: (@canvas, @mu=1)->
        @particles = []

    directParticles: ->
        unless @particles.length > @maxParticles
            @particles.push(@newParticles()) for [1..@rate]
            
        @particles = @particles.filter (p) => p.visible()
        for particle in @particles
            particle.move()
            particle.draw()

    newParticles: ->
        position = new Vector @cw*Math.random(), @ch*Math.random()
        new Particle @canvas, position, @mu 

    updateMu: ->
        for particle in @particles
            particle.mu = @mu

    
class Checkbox

    constructor: (@id, @change) ->
        @checkbox = $ "##{id}"
        @checkbox.unbind()  # needed to clear event handlers
        @checkbox.on "change", =>
            val = @val()
            @change val
        
    val: -> @checkbox.is(":checked")
    
class d3Object

    constructor: (id) ->
        @element = d3.select "##{id}"
        @element.selectAll("svg").remove()
        @obj = @element.append "svg"
        @initAxes()
        
    append: (obj) -> @obj.append obj
    
    initAxes: -> 

        
class Oscillator extends d3Object
        
    margin = Figure.margin
    width = Figure.width
    height = Figure.height

    constructor: (X) ->
        super X 

        @obj.on("click", null)  # Clear any previous event handlers.
        #@obj.on("click", => @click())
        d3.behavior.drag().on("drag", null)  # Clear any previous event handlers.
       
        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("id", "oscillator")

        @obj.append("g")
            .attr("class", "axis")
            .attr("transform",
                "translate(#{margin.left}, #{margin.top+height+10})")
            .call(@xAxis) 

        @obj.append("g")
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left-10}, #{margin.top})")
            .call(@yAxis) 

        @plot = @obj.append("g")
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        @limitCircle = @plot.append("circle")
            .attr("cx", @xscale(0)+margin.left*0)
            .attr("cy", @yscale(0)+margin.top*0)
            .attr("r", @xscale(2)-@xscale(0))
            .style("fill", "transparent")
            .style("stroke", "ccc")

        @marker0 = @marker("black")
        @marker1 = @marker("red")
        
        @guide0 = @radialLine()
        @guide1 = @radialLine()


    marker: (color) ->
        m = @plot.append("circle")
            .attr("r",10)
            .style("fill", color)
            .style("stroke", color)
            .style("stroke-width","1")
            .call(
                d3.behavior
                .drag()
                .origin(=>
                    x:m.attr("cx")
                    y:m.attr("cy")
                )
                .on("drag", => @dragMarker(m, d3.event.x, d3.event.y))
            )

        
    radialLine: ->
        @plot.append('line')
            .attr("x1", @xscale 0)
            .attr("y1", @yscale 0)
            .style("stroke","ccc")
            .style("stroke-width","1")
        
    dragMarker: (marker, u, v) ->
        marker.attr("cx", u)
        marker.attr("cy", v)

    # !!! duplicated.
    moveMarker: (marker, u, v) ->
        marker.attr("cx", u)
        marker.attr("cy", v)

    moveGuide: (guide, u, v) ->
        guide.attr("x2", u)
        guide.attr("y2", v)
         
    initAxes: ->

        @xscale = d3.scale.linear()
            .domain([-Figure.xMax, Figure.xMax])
            .range([0, width])

        @xAxis = d3.svg.axis()
            .scale(@xscale)
            .orient("bottom")

        @yscale = d3.scale.linear()
            .domain([-Figure.yMax, Figure.yMax])
            .range([height, 0])

        @yAxis = d3.svg.axis()
            .scale(@yscale)
            .orient("left")


class Disturbance extends d3Object
        
    margin = Figure.margin
    width = Figure.width
    height = Figure.height
    n = 0
    phiP = 0
    phiM = 0
    omega = 1 # degree/step
    omegaP = 0
    omegaM = 0

    constructor: (X) ->
        super X 

        @spin = 0

        # Clear any previous event handlers.
        @obj.on("click", null)  
        d3.behavior.drag().on("drag", null)
       
        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("id", "disturbance")

        @obj.append("svg:defs")
            .append("svg:marker")
            .attr("id", "arrow")
            .attr("viewBox", "0 -5 10 10")
            .attr("refX", 10)
            .attr("refY", 0)
            .attr("markerWidth", 6)
            .attr("markerHeight", 6)
            .attr("orient", "auto")
            .append("svg:path")
            .attr("d", "M0,-5L10,0L0,5")
            .style("stroke","ccc")

        @obj.append("g")
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left-10}, #{margin.top})")
            .call(@yAxis) 

        @plot = @obj.append("g")
            .attr("id", "plot")
            .attr("transform", "translate(#{margin.left},#{margin.top})")

        @markerDistInner = @vector @plot, 0, 1.5
        @markerDistOuter = @vector @plot, 0, 1.5
        
        @markerEquiv1 = @vector @plot, 0, 0.75
        @markerEquiv2 = @vector @plot, 0, 0.75

        @markerSoln = @plot.append("circle")
            .attr("id", "marker-solution")
            .attr("r", 10)
            .attr("cx", @xscale 0 )
            .attr("cy", @yscale 4 )
            .attr("stroke", "black")
            .attr("fill", "transparent")

        @plot.append("circle")
            .attr("r", @xscale(0.75)-@xscale(0))
            .attr("cx", @xscale 0 )
            .attr("cy", @yscale 0 )
            .attr("stroke", "black")
            .attr("fill", "transparent")

        @plot.append("circle")
            .attr("r", @xscale(4)-@xscale(0))
            .attr("cx", @xscale 0 )
            .attr("cy", @yscale 0 )
            .attr("stroke", "black")
            .attr("fill", "transparent")
            .style("stroke-dasharray", ("10,3"))
            .attr("visibility", "visible")

        @ticks = @plot.append("g")
            .attr("id", "ticks")
            .attr("transform", "translate(#{0},#{0})")

        @ticks.selectAll("rect.tick")
            .data(d3.range(24))
            .enter()
            .append("rect")
            .attr("class", "tick")
            .attr("x", 0)
            .attr("y", 70)
            .attr("width", 1)
            .attr("height", (d, i) -> (if (i % 2) then 0 else 15*6))
            .attr("transform", (d, i) =>
                "translate(#{@xscale 0},#{@xscale 0}) rotate(#{i*15+150})"
            )
            .attr("fill", "steelblue")

        @rotate(false)


    vector: (U, x, y) ->

        U.append('line')
            .attr("marker-end", "url(#arrow)")
            .attr("x1", @xscale 0).attr("y1", @yscale x)
            .attr("x2", @xscale 0).attr("y2", @yscale y)
            .attr('id','weightGuideDim')
            .style("stroke","black")
            .style("stroke-width","1")

    rotate: (spin) ->

        if spin
            omegaP = 2*omega
            omegaM = 0
        else
            omegaP = omega
            omegaM = omega
            phiP = 0
            phiM = 0

    move: () ->
        phiP += omegaP # degrees
        phiM += omegaM

        @mag = 1.5*Math.sin(phiM*pi/180)
        
        @markerDistInner.attr("y2", @yscale @mag)
        @markerDistOuter
            .attr("x1", @xscale -4*COS(phiM)).attr("y1", @yscale 4*SIN(phiM))
            .attr("x2", @xscale -4*COS(phiM)).attr("y2", @yscale 4*SIN(phiM)+@mag)
        center = "#{@xscale(0)} #{@yscale(0)}"
        @markerEquiv1.attr("transform", "rotate(#{-phiP+90} #{center} )")
        @markerEquiv2.attr("transform", "rotate(#{phiM-90} #{center} )")
        @markerSoln.attr("transform", "rotate(#{phiM-90} #{center} )")
        @ticks.attr("transform", "rotate(#{phiM} #{center} )")
         
    initAxes: ->
        @xscale = d3.scale.linear()
            .domain([-Figure.xMax, Figure.xMax])
            .range([0, width])

        @yscale = d3.scale.linear()
            .domain([-Figure.yMax, Figure.yMax])
            .range([height, 0])

        @yAxis = d3.svg.axis()
            .scale(@yscale)
            .orient("left")

class Scope extends d3Object

    margin = Figure.margin
    width = Figure.width
    height = Figure.height
    
    constructor: (@spec)->
        
        @hist = repRow(@spec.initVal, @spec.N) # Repeat initial

        super @spec.scope

        #@obj.attr('width', width)
        #    .attr('height', height)
        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("id", "oscillator")

        @obj.append("g")
            .attr("class", "axis")
            .attr("transform","translate(#{0}, #{0})")
            .call(@yAxis) 

        @screen = @obj.append('g')
            .attr("id", "screen")
            .attr('width', width)
            .attr('height', height)
            .attr("transform","translate(#{margin.left}, #{margin.top})")

        gradient = @obj.append("svg:defs") # https://gist.github.com/mbostock/1086421
            .append("svg:linearGradient")
            .attr("id", "gradient")
            .attr("x1", "100%")
            .attr("y1", "100%")
            .attr("x2", "0%")
            .attr("y2", "100%")
            .attr("spreadMethod", "pad");

        gradient.append("svg:stop")
            .attr("offset", "0%")
            .attr("stop-color", "white")
            .attr("stop-opacity", 1);

        gradient.append("svg:stop")
            .attr("offset", "100%")
            .attr("stop-color", @spec.color)
            .attr("stop-opacity", 1);

        @line = d3.svg.line()
            .x((d) =>  @x(d))
            .y((d,i) =>  @hist[i])
            .interpolate("basis")

        if @spec.fade
            strokeSpec = "url(#gradient)"
        else
            strokeSpec = @spec.color    
                                           
        @screen.selectAll('path.trace')
            .data([[0...@spec.N]])
            .enter()
            .append("path")
            .attr("d", @line)
            .attr("class", "trace")
            .style("stroke", strokeSpec)
            .style("stroke-width", 2)

    draw: (val) ->
        @hist.unshift val
        @hist = @hist[0...@hist.length-1]
        @screen.selectAll('path.trace').attr("d", @line)

    show: (bit) ->
        if bit
            @obj.attr("visibility", "visible")
        else
            @obj.attr("visibility", "hidden")
                                                                    
    initAxes: ->
        
        @y = d3.scale.linear()
            .domain([-@spec.yMin, @spec.yMax])
            .range([0, height])

        @x = d3.scale.linear()
            .domain([0, @spec.N-1])
            .range([0, width])

        @xAxis = d3.svg.axis()
            .scale(@x)
            .orient("bottom")
            .tickFormat(d3.format("d"))

        @yAxis = d3.svg.axis()
            .scale(@y)
            .orient("left")

class IntroSim

    constructor: ->

        @canvas = new Canvas "#intro-vector-field"

        @oscillator = new Oscillator "intro-oscillator"
        
        @vectorField = new Emitter @canvas

        @markerPoint = new vfPoint
        @markerPoint.pos.x = @markerPoint.x 3
        @markerPoint.pos.y = @markerPoint.y -3

        specX =
            scope : "x-scope"
            initVal : @markerPoint.pos.x
            color : "green"
            yMin : -4
            yMax : 4
            width : Figure.width
            height : Figure.height
            N: 255
            fade: 0
        specY =
            scope : "y-scope"
            initVal: @markerPoint.pos.y
            color : "red"
            yMin : -4
            yMax : 4
            width : Figure.width
            height : Figure.height
            N: 255
            fade: 0
        @scopeX = new Scope specX
        @scopeY = new Scope specY

        @persist = new Checkbox "persist" , (v) =>  @.checked = v

        $("#mu-slider").on "change", => @updateMu()
        @updateMu()

        d3.selectAll("#intro-stop-button").on "click", => @stop()
        d3.selectAll("#intro-start-button").on "click", => @start()

        setTimeout (=> @animate() ), 2000

    updateMu: ->
        k = parseFloat(d3.select("#mu-slider").property("value"))
        @markerPoint.mu = k
        @vectorField.mu = k
        @vectorField.updateMu() 
        d3.select("#mu-value").html(k)
        
    snapshot1: ->
        @canvas.clear() if not @.checked
        @vectorField.directParticles()
        @drawMarker()

    snapshot2: ->
        @scopeX.draw @markerPoint.pos.x
        @scopeY.draw @markerPoint.pos.y

    drawMarker: ->
        @markerPoint.move()
        @oscillator.moveMarker(@oscillator.marker0, @markerPoint.pos.x, @markerPoint.pos.y)

    animate: ->
        @timer1 = setInterval (=> @snapshot1()), 20
        @timer2 = setInterval (=> @snapshot2()), 50

    stop: ->
        clearInterval @timer1
        clearInterval @timer2
        @timer1 = null
        @timer2 = null

    start: ->
        setTimeout (=> @animate() ), 20


class DistSim

    # Illustrate effect of disturbances with two phase trajectories.
    
    constructor: (@u0=3, @v0=-3, @u1=3, @v1=2) ->

        @oscillator = new Oscillator "dist-oscillator"
        @canvas = new Canvas "#dist-vector-field"
        @point0 = new vfPoint
        @point1 = new vfPoint
        
        @initPointMarker(@point0, @u0, @v0, @oscillator.marker0)
        @initPointMarker(@point1, @u1, @v1, @oscillator.marker1)

        d3.selectAll("#dist-stop-button").on "click", => @stop()
        d3.selectAll("#dist-start-button").on "click", => @start()

        setTimeout (=> @start() ), 2000

    initPointMarker: (point, u, v, marker) ->
        # initialize vector field point at (u,v) and sync marker
        point.pos.x = point.x u # convert to screen units
        point.pos.y = point.y v
        point.mu = 0.1
        marker.attr("cx", point.pos.x)
        marker.attr("cy", point.pos.y)

    snapshot: ->
        @drawMarker()
        @canvas.square {x:@point0.pos.x, y:@point0.pos.y}, 2, "black"
        @canvas.square {x:@point1.pos.x, y:@point1.pos.y}, 2, "red"

    drawMarker: ->
        @point0.move()
        @point1.move()
        @oscillator.moveMarker(@oscillator.marker0, @point0.pos.x, @point0.pos.y)
        @oscillator.moveMarker(@oscillator.marker1, @point1.pos.x, @point1.pos.y)
        @oscillator.moveGuide(@oscillator.guide0, @point0.pos.x, @point0.pos.y)
        @oscillator.moveGuide(@oscillator.guide1, @point1.pos.x, @point1.pos.y)

    animate: ->
        @timer = setInterval (=> @snapshot()), 20

    stop: ->
        clearInterval @timer
        @timer = null

    start: ->
        
        # Update vector field points (marker may have been dragged).
        @point0.pos.x = @oscillator.marker0.attr("cx")
        @point0.pos.y = @oscillator.marker0.attr("cy")
        @point1.pos.x = @oscillator.marker1.attr("cx")
        @point1.pos.y = @oscillator.marker1.attr("cy")

        @canvas.clear()
        
        setTimeout (=> @animate() ), 20


class SyncSim

    # Illustrate synchronization in rotating frame.
    
    constructor:  ->
        @disturbance = new Disturbance "sync-oscillator"

        spec =
            scope : "sync-scope"
            initVal: 160
            color : "green"
            yMin : -4
            yMax : 4
            width : 320
            height : 320
            N: 101
            fade: 1  
        @scope = new Scope spec

        new Checkbox "trace" , (v) =>  @scope.show(v)
        new Checkbox "spin" , (v) =>  @disturbance.rotate(v)

        setTimeout (=> @animate() ), 2000

    animate: ->
        @timer1 = setInterval (=> @snapshot1()), 20
        @timer2 = setInterval (=> @snapshot2()), 50

    snapshot1: ->
        @disturbance.move()

    snapshot2: ->
        @scope.draw(@disturbance.yscale @disturbance.mag)


#new IntroSim
new DistSim
#new SyncSim

#d3.selectAll("#stop-button").on "click", ->
#    distSim.stop()
