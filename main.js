// Generated by CoffeeScript 1.3.3
(function() {
  var Canvas, Chart, Checkbox, Emitter, Particle, Simulation, StopButton, Vector, WebFontConfig, char, cos, d3Object, f, min, ode, pi, repRow, rk, sin, xMax, yMax, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Number.prototype.pow = function(p) {
    return Math.pow(this, p);
  };

  WebFontConfig = {
    google: {
      families: ["Reenie+Beanie::latin"]
    }
  };

  pi = Math.PI;

  sin = Math.sin;

  cos = Math.cos;

  min = Math.min;

  repRow = function(val, m) {
    var _i, _results;
    _results = [];
    for (_i = 1; 1 <= m ? _i <= m : _i >= m; 1 <= m ? _i++ : _i--) {
      _results.push(val);
    }
    return _results;
  };

  xMax = 4;

  yMax = 4;

  _ref = $blab.ode, rk = _ref.rk, ode = _ref.ode;

  char = function(id, code) {
    return $("." + id).html("&" + code + ";");
  };

  char("deg", "deg");

  char("percent", "#37");

  char("equals", "#61");

  d3Object = (function() {

    function d3Object(id) {
      this.element = d3.select("#" + id);
      this.element.selectAll("svg").remove();
      this.obj = this.element.append("svg");
      this.initAxes();
    }

    d3Object.prototype.append = function(obj) {
      return this.obj.append(obj);
    };

    d3Object.prototype.initAxes = function() {};

    return d3Object;

  })();

  f = function(t, v) {
    return [v[0] - v[0].pow(3) / 3 + v[1], -v[0]];
  };

  Vector = (function() {
    var z;

    z = function() {
      return new Vector;
    };

    function Vector(x, y) {
      this.x = x != null ? x : 0;
      this.y = y != null ? y : 0;
    }

    Vector.prototype.add = function(v) {
      if (v == null) {
        v = z();
      }
      this.x += v.x;
      this.y += v.y;
      return this;
    };

    Vector.prototype.mag = function() {
      return Math.sqrt(this.x * this.x + this.y * this.y);
    };

    Vector.prototype.ang = function() {
      return Math.atan2(this.y, this.x);
    };

    Vector.prototype.polar = function(m, a) {
      this.x = m * Math.cos(a);
      this.y = m * Math.sin(a);
      return this;
    };

    return Vector;

  })();

  Canvas = (function() {

    function Canvas() {}

    Canvas.width = 320;

    Canvas.height = 320;

    Canvas.canvas = $("#vector-field")[0];

    Canvas.canvas.width = Canvas.width;

    Canvas.canvas.height = Canvas.height;

    Canvas.ctx = Canvas.canvas.getContext('2d');

    Canvas.clear = function() {
      return this.ctx.clearRect(0, 0, this.width, this.height);
    };

    Canvas.square = function(pos, size, color) {
      this.ctx.fillStyle = color;
      return this.ctx.fillRect(pos.x, pos.y, size, size);
    };

    return Canvas;

  })();

  Particle = (function() {
    var height, width;

    width = Canvas.width;

    height = Canvas.height;

    function Particle(pos) {
      this.pos = pos;
      this.size = 2;
      this.color = ["red", "green", "blue"][Math.floor(3 * Math.random())];
      this.vel = new Vector(0, 0);
      this.vf = new Vector(0, 0);
      this.d = 0;
      this.scales();
      this.update();
      this.draw();
    }

    Particle.prototype.visible = function() {
      var _ref1, _ref2;
      return ((0 <= (_ref1 = this.pos.x) && _ref1 <= width)) && ((0 <= (_ref2 = this.pos.y) && _ref2 <= height)) && this.vel.mag() > 0 && this.d < 1200;
    };

    Particle.prototype.draw = function() {
      return Canvas.square(this.pos, this.size, this.color);
    };

    Particle.prototype.move = function() {
      var w;
      this.update();
      w = ode(rk[1], f, [0, 0.02], [this.vf.x, this.vf.y])[1];
      this.pos.x = this.x(w[0]);
      this.pos.y = this.y(w[1]);
      return this.d += this.vel.mag();
    };

    Particle.prototype.update = function() {
      var vel;
      this.vf.x = this.x.invert(this.pos.x);
      this.vf.y = this.y.invert(this.pos.y);
      vel = f(0, [this.vf.x, this.vf.y]);
      this.vel.x = this.x.invert(vel[0]);
      return this.vel.y = this.y.invert(vel[1]);
    };

    Particle.prototype.scales = function() {
      this.x = d3.scale.linear().domain([-xMax, xMax]).range([0, width]);
      return this.y = d3.scale.linear().domain([-yMax, yMax]).range([height, 0]);
    };

    return Particle;

  })();

  Emitter = (function() {

    Emitter.prototype.maxParticles = 500;

    Emitter.prototype.rate = 3;

    Emitter.prototype.ch = Canvas.height;

    Emitter.prototype.cw = Canvas.width;

    function Emitter() {
      this.particles = [];
    }

    Emitter.prototype.directParticles = function() {
      var particle, _i, _j, _len, _ref1, _ref2, _results,
        _this = this;
      if (!(this.particles.length > this.maxParticles)) {
        for (_i = 1, _ref1 = this.rate; 1 <= _ref1 ? _i <= _ref1 : _i >= _ref1; 1 <= _ref1 ? _i++ : _i--) {
          this.particles.push(this.newParticles());
        }
      }
      this.particles = this.particles.filter(function(p) {
        return p.visible();
      });
      _ref2 = this.particles;
      _results = [];
      for (_j = 0, _len = _ref2.length; _j < _len; _j++) {
        particle = _ref2[_j];
        particle.move();
        _results.push(particle.draw());
      }
      return _results;
    };

    Emitter.prototype.newParticles = function() {
      var position;
      position = new Vector(this.cw * Math.random(), this.ch * Math.random());
      return new Particle(position);
    };

    return Emitter;

  })();

  StopButton = (function() {

    StopButton.prototype.id = "stop_simulation_button";

    function StopButton(stop) {
      var _this = this;
      this.stop = stop;
      this.button = $("#" + this.id);
      if (this.button.length) {
        this.button.remove();
      }
      this.button = $("<button>", {
        id: this.id,
        type: "button",
        text: "Stop",
        title: "Stop simulation",
        click: function() {
          return _this.stop();
        },
        css: {
          fontSize: "7pt",
          width: "50px",
          marginLeft: "5px"
        }
      });
      $("#run_button_container").append(this.button);
    }

    StopButton.prototype.text = function(t) {
      return this.button.text(t);
    };

    StopButton.prototype.remove = function() {
      return this.button.remove();
    };

    return StopButton;

  })();

  Checkbox = (function() {

    function Checkbox(id, change) {
      var _this = this;
      this.id = id;
      this.change = change;
      this.checkbox = $("#" + id);
      this.checkbox.unbind();
      this.checkbox.on("change", function() {
        var val;
        val = _this.val();
        return _this.change(val);
      });
    }

    Checkbox.prototype.val = function() {
      return this.checkbox.is(":checked");
    };

    return Checkbox;

  })();

  d3Object = (function() {

    function d3Object(id) {
      this.element = d3.select("#" + id);
      this.element.selectAll("svg").remove();
      this.obj = this.element.append("svg");
      this.initAxes();
    }

    d3Object.prototype.append = function(obj) {
      return this.obj.append(obj);
    };

    d3Object.prototype.initAxes = function() {};

    return d3Object;

  })();

  Chart = (function(_super) {
    var height, margin, width;

    __extends(Chart, _super);

    margin = {
      top: 65,
      right: 65,
      bottom: 65,
      left: 65
    };

    width = 450 - margin.left - margin.right;

    height = 450 - margin.top - margin.bottom;

    function Chart() {
      Chart.__super__.constructor.call(this, "chart");
      this.obj.attr("width", width + margin.left + margin.right);
      this.obj.attr("height", height + margin.top + margin.bottom);
      this.obj.attr("class", "chart");
      this.obj.attr("id", "chart");
      this.obj.append("g").attr("class", "axis").attr("transform", "translate(" + margin.left + ", " + (margin.top + height + 10) + ")").call(this.xAxis);
      this.obj.append("g").attr("class", "axis").attr("transform", "translate(" + (margin.left - 10) + ", " + margin.top + ")").call(this.yAxis);
    }

    Chart.prototype.initAxes = function() {
      this.xscale = d3.scale.linear().domain([-xMax, xMax]).range([0, width]);
      this.xAxis = d3.svg.axis().scale(this.xscale).orient("bottom");
      this.yscale = d3.scale.linear().domain([-yMax, yMax]).range([height, 0]);
      return this.yAxis = d3.svg.axis().scale(this.yscale).orient("left");
    };

    return Chart;

  })(d3Object);

  Simulation = (function() {

    function Simulation() {
      var _this = this;
      this.emitter = new Emitter;
      setTimeout((function() {
        return _this.animate();
      }), 2000);
      this.stopButton = new StopButton(function() {
        return _this.stop();
      });
      this.persist = new Checkbox("persist", function(v) {
        return _this.checked = v;
      });
    }

    Simulation.prototype.snapshot = function() {
      if (!this.checked) {
        Canvas.clear();
      }
      return this.emitter.directParticles();
    };

    Simulation.prototype.animate = function() {
      var _this = this;
      return this.timer = setInterval((function() {
        return _this.snapshot();
      }), 50);
    };

    Simulation.prototype.stop = function() {
      var _ref1;
      clearInterval(this.timer);
      this.timer = null;
      if ((_ref1 = this.stopButton) != null) {
        _ref1.remove();
      }
      return $("#run_button").prop("disabled", false);
    };

    return Simulation;

  })();

  new Chart;

  new Simulation;

}).call(this);
