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
repRow = (val, m) -> val for [1..m]

xMax = 4 # horizontal plot limit
yMax = 4 # vertical plot limit

{rk, ode} = $blab.ode # Import ODE solver

#mu = 1


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

class Canvas

    @margin = {left:65, top: 65} 
    @width = 450 - @margin.left - @margin.top
    @height = 450 - @margin.left - @margin.top

    @canvas = $("#vector-field")
    @canvas.css("left","#{@margin.left}px").css("top","#{@margin.top}px")
    @canvas[0].width = @width
    @canvas[0].height = @height

    @ctx = @canvas[0].getContext('2d')
    @clear: -> @ctx.clearRect(0, 0, @width, @height)
    @square: (pos, size, color) ->
        @ctx.fillStyle = color
        @ctx.fillRect(pos.x, pos.y, size, size)

class vfPoint # vector field point

    width  = 320
    height = 320
    
    constructor: (@pos={x:0, y:0}, @mu=1) ->
    #constructor: () ->

        #@mu = 1 # VdP nonlinearity

        #@pos = {x:0, y:0} # position
        #console.log "pos>>>", @pos
        @vel = new Vector 0, 0 # velocity
        @vf = new Vector 0, 0 # vector-field coords
        @d = 0 # distance

        @scales() # funcs to X-form between screen position and VF coords
        @update() # VF coords and velocity
        @draw()

    scales: ->
        
        @x = d3.scale.linear()
            .domain([-xMax, xMax])
            .range([0, width])
        @y = d3.scale.linear()
            .domain([-yMax, yMax])
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

    constructor: (Z, mu) ->
        super Z, mu

        @size = 2
        @color = ["red", "green", "blue"][Math.floor(3*Math.random())]

    draw: ->
        Canvas.square @pos, @size, @color

            
class Emitter
    
    maxParticles: 500
    rate: 3
    ch: Canvas.height
    cw: Canvas.width
    
    constructor: (@mu=1)->
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
        new Particle position, @mu 

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
        
    margin = {top: 65, right: 65, bottom: 65, left: 65}
    width = Canvas.width # 450 - margin.left - margin.right
    height = Canvas.height # 450 - margin.top - margin.bottom

    constructor: (X) ->
        super X 

        @obj.on("click", null)  # Clear any previous event handlers.
        #@obj.on("click", => @click())
        d3.behavior.drag().on("drag", null)  # Clear any previous event handlers.
       
        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("class","oscillator")
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

        @limitCircle = @obj.append("circle")
            .attr("cx", @xscale(0)+margin.left)
            .attr("cy", @yscale(0)+margin.top)
            .attr("r", @xscale(2)-@xscale(0))
            .style("fill", "transparent")
            .style("stroke", "ccc")

        @marker0 = @obj.append("circle")
            .attr("r", 5)
            .style("fill", "black")
            .style("stroke", "000")
            .style("stroke-width", "1")
            .call(
                d3.behavior
                .drag()
                .origin(()=>{x:@marker0.attr("cx"), y:@marker0.attr("cy")})
                .on("drag", => @dragMarker(@marker0, d3.event.x, d3.event.y))
            )

        @marker1 = @obj.append("circle")
            .attr("r",10)
            .style("fill","red")
            .style("stroke","000")
            .style("stroke-width","1")
            .call(
                d3.behavior
                .drag()
                .origin(()=>{x:@marker1.attr("cx"), y:@marker1.attr("cy")})
                .on("drag", => @dragMarker(@marker1, d3.event.x, d3.event.y))
            )

    dragMarker: (marker, u, v) ->
            marker.attr("cx", u)
            marker.attr("cy", v)

    moveMarker: (marker, u, v) ->
            marker.attr("cx", u + margin.left)
            marker.attr("cy", v + margin.top)
         
    initAxes: ->

        @xscale = d3.scale.linear()
            .domain([-xMax, xMax])
            .range([0, width])

        @xAxis = d3.svg.axis()
            .scale(@xscale)
            .orient("bottom")

        @yscale = d3.scale.linear()
            .domain([-yMax, yMax])
            .range([height, 0])

        @yAxis = d3.svg.axis()
            .scale(@yscale)
            .orient("left")


class Scope extends d3Object

    # Screen width/height & margins to scope edge
    margin = {top: 0, right: 0, bottom: 0, left: 0}
    width = Canvas.width - margin.left - margin.right
    height = Canvas.height - margin.top - margin.bottom

    constructor: (scope, initVal, color)->

        # Repeat initial value @N times
        @N = 1001
        @hist = repRow(initVal, @N)

        super scope

        @obj.attr('width', width + margin.left + margin.right)
            .attr('height', height + margin.top + margin.bottom)

        @screen = @obj.append('g')
            .attr("id", "screen")
            .attr('transform', "translate(#{margin.left}, #{margin.top})")
            .attr('width', width)
            .attr('height', height)

        @obj.append("linearGradient")
            .attr("id", "line-gradient")
            .attr("gradientUnits", "userSpaceOnUse")
            .attr("x1", width).attr("y1", 0)
            .attr("x2", 0).attr("y2", 0)
            .selectAll("stop").data([
                {
                    offset: "0%"
                    color: "white"
                }
                {
                    offset: "100%"
                    color: color
                }
            ])
            .enter()
            .append("stop")
            .attr("offset", (d) -> d.offset )
            .attr("stop-color", (d) -> d.color)

        @line = d3.svg.line()
            .x((d) =>  @x(d))
            .y((d,i) =>  @hist[i])
            .interpolate("basis")
                                           
        @screen.selectAll('path.trace')
            .data([[0...@N]])
            .enter()
            .append("path")
            .attr("d", @line)
            .attr("class", "trace")
                                                                    
    initAxes: ->
        
        @y = d3.scale.linear()
            .domain([-4, 4])
            .range([0, height])

        @x = d3.scale.linear()
            .domain([0, @N-1])
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

        @oscillator = new Oscillator "intro-oscillator"
        
        @vectorField = new Emitter

        @markerPoint = new vfPoint
        @markerPoint.pos.x = @markerPoint.x 3
        @markerPoint.pos.y = @markerPoint.y -3

        @scopeX = new Scope "x-scope", @markerPoint.pos.x, "green"
        @scopeY = new Scope "y-scope", @markerPoint.pos.y, "blue"

        @persist = new Checkbox "persist" , (v) =>  @.checked = v

        $("#mu-slider").on "change", => @updateMu()
        @updateMu()

        setTimeout (=> @animate() ), 2000

    updateMu: ->
        k = parseFloat(d3.select("#mu-slider").property("value"))
        @markerPoint.mu = k
        @vectorField.mu = k
        @vectorField.updateMu() 
        d3.select("#mu-value").html(k)
        
    snapshot: ->
        Canvas.clear() if not @.checked
        @vectorField.directParticles()
        @drawMarker()
        @drawScope(@scopeX, @markerPoint.pos.x)
        @drawScope(@scopeY, @markerPoint.pos.y)

    drawMarker: ->
        @markerPoint.move()
        @oscillator.moveMarker(@oscillator.marker0, @markerPoint.pos.x, @markerPoint.pos.y)

    drawScope: (scope, val)->
        (scope.hist).unshift val
        scope.hist = scope.hist[0...(scope.hist).length-1]
        scope.screen.selectAll('path.trace').attr("d", scope.line)
        
    animate: ->
        @timer = setInterval (=> @snapshot()), 50

class DistSim

    constructor: ->

        @oscillator = new Oscillator "dist-oscillator"
        
        @markerPoint0 = new vfPoint
        @markerPoint0.pos.x = @markerPoint0.x 3
        @markerPoint0.pos.y = @markerPoint0.y -3
        @markerPoint0.mu = 0.1

        @markerPoint1 = new vfPoint
        @markerPoint1.pos.x = @markerPoint1.x 3
        @markerPoint1.pos.y = @markerPoint1.y 2
        @markerPoint1.mu = 0.1

        d3.selectAll("#stop-button").on "click", => @stop()
        d3.selectAll("#start-button").on "click", => @start()

        setTimeout (=> @animate() ), 2000

    snapshot: ->
        @drawMarker()

    drawMarker: ->
        @markerPoint0.move()
        @markerPoint1.move()
        @oscillator.moveMarker(@oscillator.marker0, @markerPoint0.pos.x, @markerPoint0.pos.y)
        @oscillator.moveMarker(@oscillator.marker1, @markerPoint1.pos.x, @markerPoint1.pos.y)

    animate: ->
        @timer = setInterval (=> @snapshot()), 20

    stop: ->
        clearInterval @timer
        @timer = null

    start: ->
        setTimeout (=> @animate() ), 20

        
#introSim = new IntroSim
distSim = new DistSim


#d3.selectAll("#stop-button").on "click", ->
#    distSim.stop()
