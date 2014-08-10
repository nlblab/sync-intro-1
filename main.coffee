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


# work around unicode issue
char = (id, code) -> $(".#{id}").html "&#{code};"
char "deg", "deg"
char "percent", "#37"
char "equals", "#61"


# Vector field (<a href="http://en.wikipedia.org/wiki/Van_der_Pol_oscillator">Van der Pol</a>)

# VdP equation
f = (t, v) -> 
	[
    v[0]-v[0].pow(3)/3+v[1] # $\dot{x} = x - x^3/3 + y$
    -v[0] # $\dot{y} = -x$
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

    @width = 320
    @height = 320
    
    @canvas = $("#vector-field")[0]
    @canvas.width = @width
    @canvas.height = @height
    @ctx = @canvas.getContext('2d')
    @clear: -> @ctx.clearRect(0, 0, @width, @height)
    
    @square: (pos, size, color) ->
        @ctx.fillStyle = color
        @ctx.fillRect(pos.x, pos.y, size, size)


class vfPoint # vector field point

    width  = 320
    height = 320
    
    constructor: (@pos={x:0, y:0}) ->

        @vel = new Vector 0, 0 # velocity
        @vf = new Vector 0, 0 # VF coords
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
        vel = f(0, [@vf.x, @vf.y])
        @vel.x = @x.invert vel[0]
        @vel.y = @y.invert vel[1]

    draw: ->

    move: ->

        @update()
        
        # Runge Kutta step
        w = ode(rk[1], f, [0, 0.02], [@vf.x, @vf.y])[1]
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

    constructor: (Z) ->
        super Z

        @size = 2
        @color = ["red", "green", "blue"][Math.floor(3*Math.random())]

    draw: ->
        Canvas.square @pos, @size, @color

            
class Emitter

    maxParticles: 500
    rate: 3
    ch: Canvas.height
    cw: Canvas.width
    
    constructor: ->
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
        new Particle position 
            
class StopButton

    id: "stop_simulation_button"

    constructor: (@stop) ->
        @button = $ "##{@id}"
        @button.remove() if @button.length
        @button = $ "<button>",
            id: @id
            type: "button"
            text: "Stop"
            title: "Stop simulation"
            click: => @stop()
            css:
                fontSize: "7pt"
                width: "50px"
                marginLeft: "5px"
        $("#run_button_container").append @button
 
    text: (t) ->
        @button.text t
        
    remove: -> @button.remove()
    
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
        
class Chart extends d3Object
        
    margin = {top: 65, right: 65, bottom: 65, left: 65}
    width = Canvas.width # 450 - margin.left - margin.right
    height = Canvas.height # 450 - margin.top - margin.bottom

    constructor: () ->
        super "chart"
       
        @obj.attr("width", width + margin.left + margin.right)
        @obj.attr("height", height + margin.top + margin.bottom)
        @obj.attr("class","chart")
        @obj.attr("id", "chart")

        @obj.append("g")
            .attr("class", "axis")
            .attr("transform",
                "translate(#{margin.left}, #{margin.top+height+10})")
            .call(@xAxis) 

        @obj.append("g")
            .attr("class", "axis")
            .attr("transform","translate(#{margin.left-10}, #{margin.top})")
            .call(@yAxis) 

        @marker0 = @obj.append("circle")
            .attr("r",10)
            .style("fill","black")
            .style("stroke","000")
            .style("stroke-width","1")

        @marker1 = @obj.append("circle")
            .attr("r",10)
            .style("fill","red")
            .style("stroke","000")
            .style("stroke-width","1")

    moveMarker: (marker, u, v) ->
            marker.attr('transform', "translate(#{u+margin.left},#{v+margin.top})")
        
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

class Simulation

    constructor: ->

        @emitter = new Emitter
        setTimeout (=> @animate() ), 2000
        @stopButton = new StopButton => @stop()
        @persist = new Checkbox "persist" , (v) =>  @.checked = v

        @vfp0 = new vfPoint
        @vfp0.pos.x = @vfp0.x 3
        @vfp0.pos.y = @vfp0.y -3

        @vfp1 = new vfPoint
        @vfp1.pos.x = @vfp1.x 1
        @vfp1.pos.y = @vfp1.y 1
        
    snapshot: ->
        Canvas.clear() if not @.checked
        @emitter.directParticles()
        @vfp0.move()
        @vfp1.move()
        
        chart.moveMarker(chart.marker0, @vfp0.pos.x, @vfp0.pos.y)
        chart.moveMarker(chart.marker1, @vfp1.pos.x, @vfp1.pos.y)
        
    animate: ->
        @timer = setInterval (=> @snapshot()), 50
        
    stop: ->
        clearInterval @timer
        @timer = null
        @stopButton?.remove()
        $("#run_button").prop("disabled", false)
        
chart = new Chart

new Simulation

#!end (coffee)

