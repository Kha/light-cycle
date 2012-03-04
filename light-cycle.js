(function() {
  var Char, Grid, Help, Match, Menu, Player, Trail, Vector, cps, game, v;

  Math.trunc = function(x) {
    if (x > 0) {
      return Math.floor(x);
    } else {
      return Math.ceil(x);
    }
  };

  Array.prototype.any = function(f) {
    return !this.every(function(x) {
      return !(f(x));
    });
  };

  Vector = (function() {

    function Vector(x, y) {
      this.x = x;
      this.y = y;
    }

    Vector.prototype.add = function(v2) {
      return v(this.x + v2.x, this.y + v2.y);
    };

    Vector.prototype.sub = function(v2) {
      return this.add(v2.neg());
    };

    Vector.prototype.neg = function() {
      return v(-this.x, -this.y);
    };

    Vector.prototype.eq = function(v2) {
      return this.x === v2.x && this.y === v2.y;
    };

    Vector.prototype.len = function() {
      return Math.sqrt(this.x * this.x + this.y * this.y);
    };

    Vector.dirs = [new Vector(1, 0), new Vector(0, 1), new Vector(-1, 0), new Vector(0, -1)];

    return Vector;

  })();

  v = function(x, y) {
    return new Vector(x, y);
  };

  Grid = (function() {

    function Grid(width, height) {
      var x, y;
      this.width = width;
      this.height = height;
      this.grid = (function() {
        var _ref, _results;
        _results = [];
        for (x = 0, _ref = this.width - 1; 0 <= _ref ? x <= _ref : x >= _ref; 0 <= _ref ? x++ : x--) {
          _results.push((function() {
            var _ref2, _results2;
            _results2 = [];
            for (y = 0, _ref2 = this.height - 1; 0 <= _ref2 ? y <= _ref2 : y >= _ref2; 0 <= _ref2 ? y++ : y--) {
              _results2.push(null);
            }
            return _results2;
          }).call(this));
        }
        return _results;
      }).call(this);
    }

    Grid.prototype.get = function(pos) {
      if (this.contains(pos)) return this.grid[pos.x][pos.y];
      return null;
    };

    Grid.prototype.all = function() {
      var _ref;
      return (_ref = []).concat.apply(_ref, this.grid);
    };

    Grid.prototype.set = function(x, pos) {
      if (this.contains(pos)) return this.grid[pos.x][pos.y] = x;
    };

    Grid.prototype.move = function(p1, p2) {
      this.set(this.get(p1), p2);
      return this.set(null, p1);
    };

    Grid.prototype.contains = function(pos) {
      var _ref, _ref2;
      return (0 <= (_ref = pos.x) && _ref < this.width) && (0 <= (_ref2 = pos.y) && _ref2 < this.height);
    };

    return Grid;

  })();

  cps = {
    create: function(f) {
      var cont;
      cont = f;
      return function() {
        var next;
        next = cont();
        if (next != null) return cont = next;
      };
    },
    wait: function(ticks, cont) {
      return cps["for"](ticks, (function() {}), cont);
    },
    "for": function(ticks, loopBody, cont) {
      var rec;
      rec = function(i) {
        if (i === ticks) {
          return cont;
        } else {
          return function() {
            loopBody(i);
            return rec(i + 1, loopBody, cont);
          };
        }
      };
      return rec(0);
    }
  };

  game = {
    width: 31,
    height: 31,
    dx: 16,
    dy: 16,
    setColor: function(color) {
      return this.ctx.fillStyle = this.ctx.shadowColor = color;
    },
    out: function(char, pos) {
      return this.ctx.fillText(char, pos.x * this.dx, pos.y * this.dy);
    },
    clearOut: function(char, pos) {
      this.clear(pos, 1, 1);
      return this.out(char, pos);
    },
    clear: function(pos, w, h) {
      var fillStyle;
      fillStyle = this.ctx.fillStyle;
      this.ctx.fillStyle = "black";
      this.ctx.shadowBlur = 0;
      this.ctx.fillRect(pos.x * this.dx, pos.y * this.dy, w * this.dx, h * this.dy);
      this.ctx.shadowBlur = 4;
      return this.ctx.fillStyle = fillStyle;
    },
    setScreen: function(screenGetter) {
      var _this = this;
      this.grid = new Grid(this.width, this.height);
      this.clear(v(0, 0), this.width, this.height);
      this.createBorder();
      this.screen = screenGetter();
      return this.step = cps.create(function() {
        return _this.screen.step();
      });
    },
    start: function(canvas) {
      var _this = this;
      if (!(this.ctx = canvas.getContext("2d"))) return;
      this.width = Math.floor(window.innerWidth / this.dx) - 1;
      this.height = Math.floor(window.innerHeight / this.dy) - 1;
      canvas.width = this.width * this.dx;
      canvas.height = this.height * this.dy;
      this.ctx.font = "14px monospace";
      this.ctx.textBaseline = "top";
      this.ctx.shadowBlur = 4;
      this.setScreen(function() {
        return new Menu();
      });
      return this.timer = setInterval((function() {
        return _this.step();
      }), 200);
    },
    createBorder: function() {
      var x, y, _ref, _ref2;
      for (x = 1, _ref = this.width - 2; 1 <= _ref ? x <= _ref : x >= _ref; 1 <= _ref ? x++ : x--) {
        new Char("-", v(x, 0));
        new Char("-", v(x, this.height - 1));
      }
      for (y = 1, _ref2 = this.height - 2; 1 <= _ref2 ? y <= _ref2 : y >= _ref2; 1 <= _ref2 ? y++ : y--) {
        new Char("|", v(0, y));
        new Char("|", v(this.width - 1, y));
      }
      new Char("+", v(0, 0));
      new Char("+", v(this.width - 1, 0));
      new Char("+", v(0, this.height - 1));
      return new Char("+", v(this.width - 1, this.height - 1));
    },
    refresh: function(pos) {
      var x, y, _ref, _ref2, _results;
      this.clear(pos.sub(v(2, 2)), 5, 5);
      _results = [];
      for (x = _ref = pos.x - 2, _ref2 = pos.x + 2; _ref <= _ref2 ? x <= _ref2 : x >= _ref2; _ref <= _ref2 ? x++ : x--) {
        _results.push((function() {
          var _ref3, _ref4, _ref5, _results2;
          _results2 = [];
          for (y = _ref3 = pos.y - 2, _ref4 = pos.y + 2; _ref3 <= _ref4 ? y <= _ref4 : y >= _ref4; _ref3 <= _ref4 ? y++ : y--) {
            _results2.push((_ref5 = this.grid.get(v(x, y))) != null ? _ref5.draw() : void 0);
          }
          return _results2;
        }).call(this));
      }
      return _results;
    },
    stop: function() {
      return clearInterval(this.timer);
    }
  };

  Char = (function() {

    function Char(char, pos, angle, color) {
      this.char = char;
      this.pos = pos;
      this.angle = angle != null ? angle : 0;
      this.color = color != null ? color : "white";
      game.grid.set(this, this.pos);
      this.draw();
    }

    Char.prototype.draw = function() {
      game.ctx.save();
      game.setColor(this.color);
      game.ctx.translate(game.dx * this.pos.x, game.dy * this.pos.y);
      game.ctx.rotate(this.angle * Math.PI / 2);
      game.clearOut(this.char, v(0, 0));
      return game.ctx.restore();
    };

    Char.drawString = function(string, pos, angle, color) {
      var c, chars, delta, _i, _len;
      if (angle == null) angle = 0;
      delta = Vector.dirs[angle];
      if (pos.x === -1) {
        pos = v(Math.floor((game.grid.width - string.length * delta.x) / 2), pos.y);
      }
      if (pos.y === -1) {
        pos = v(pos.x, Math.floor((game.grid.height - string.length * delta.y) / 2));
      }
      chars = [];
      for (_i = 0, _len = string.length; _i < _len; _i++) {
        c = string[_i];
        chars.push(new Char(c, pos, angle, color));
        pos = pos.add(delta);
      }
      return chars;
    };

    return Char;

  })();

  Menu = (function() {

    function Menu() {
      this.start = Char.drawString("Start!", v(-1, Math.floor(game.height / 2) - 1));
      this.help = Char.drawString("Help!", v(-1, Math.floor(game.height / 2) + 1));
      Char.drawString("Player 1", v(3, -1), 1, "orange");
      Char.drawString("Player 2", v(game.width - 1 - 3, -1), 3, "cornflowerblue");
    }

    Menu.prototype.step = function() {
      return null;
    };

    Menu.prototype.onKeyDown = function(char) {
      var _this = this;
      if (char === "\r") {
        return game.setScreen(function() {
          return new Match();
        });
      }
    };

    Menu.prototype.onTouchStart = function(pos) {
      var _this = this;
      pos = v(Math.floor(pos.x / game.dx), Math.floor(pos.y / game.dy));
      if (this.start.any((function(c) {
        return c.pos.eq(pos);
      }))) {
        return game.setScreen(function() {
          return new Match();
        });
      } else if (this.help.any((function(c) {
        return c.pos.eq(pos);
      }))) {
        return game.setScreen(function() {
          return new Help();
        });
      }
    };

    return Menu;

  })();

  Help = (function() {

    function Help() {
      var i, line, text, _len, _ref;
      text = "Manouver your light cycle quickly\nand precisely to make your\nopponents's cycle crash into the\nwall or your cycle's light trail!\nThe first player to score 15 points\nwins the game. Swipe your finger to\nchange your cycle's direction but\ndon't forget to start the swipe in\nyour respective half of the game field.";
      _ref = text.split('\n');
      for (i = 0, _len = _ref.length; i < _len; i++) {
        line = _ref[i];
        Char.drawString(line, v(-1, i + 5));
      }
      this.roger = Char.drawString("Roger!", v(-1, game.height - 1 - 3));
    }

    Help.prototype.step = function() {
      return null;
    };

    Help.prototype.onTouchStart = function(pos) {
      var _this = this;
      pos = v(Math.floor(pos.x / game.dx), Math.floor(pos.y / game.dy));
      if (this.roger.any((function(c) {
        return c.pos.eq(pos);
      }))) {
        return game.setScreen(function() {
          return new Menu();
        });
      }
    };

    return Help;

  })();

  Match = (function() {

    function Match() {
      this.score0 = this.score1 = 0;
      this.initPoint();
    }

    Match.prototype.initPoint = function() {
      var halfHeight;
      halfHeight = Math.floor((game.grid.height - 1) / 2);
      this.player0 = new Player("orange", "DSAW", v(3, halfHeight), v(1, 0));
      this.player1 = new Player("cornflowerblue", "LKJI", v(game.grid.width - 1 - 3, halfHeight), v(-1, 0));
      return this.updateScore();
    };

    Match.prototype.updateScore = function() {
      return Char.drawString(this.score0 + " : " + this.score1, v(-1, 0));
    };

    Match.prototype.step = function() {
      var _this = this;
      if (Player.tie(this.player0, this.player1)) {
        this.score0++;
        this.score1++;
      } else if (this.player0.step()) {
        this.score1++;
      } else if (this.player1.step()) {
        this.score0++;
      } else {
        return null;
      }
      this.updateScore();
      if (Math.max(this.score0, this.score1) === 15) {
        return cps.wait(10, function() {
          return game.setScreen(function() {
            return new Menu();
          });
        });
      }
      return cps.wait(5, function() {
        _this.initPoint();
        game.setScreen(function() {
          return _this;
        });
        return _this.updateScore();
      });
    };

    Match.prototype.onKeyDown = function(char) {
      this.player0.onKeyDown(char);
      return this.player1.onKeyDown(char);
    };

    Match.prototype.onTouchStart = function(pos, identifier) {
      if (pos.x / game.dx < game.width / 2) {
        this.player0.onTouchStart(pos, identifier);
        return this.player1.touchStart = null;
      } else {
        this.player1.onTouchStart(pos, identifier);
        return this.player0.touchStart = null;
      }
    };

    Match.prototype.onTouchMove = function(pos, identifier) {
      this.player0.onTouchMove(pos, identifier);
      return this.player1.onTouchMove(pos, identifier);
    };

    return Match;

  })();

  Player = (function() {

    Player.prototype.score = 0;

    Player.prototype.score2 = Player.score;

    function Player(color, keyconf, pos, dir) {
      this.color = color;
      this.keyconf = keyconf;
      this.pos = pos;
      this.dir = dir;
      game.grid.set(this, this.pos);
      this.newdir = this.dir;
    }

    Player.prototype.step = function() {
      var _this = this;
      if (this.stepCont == null) {
        this.stepCont = cps.create(function() {
          return cps["for"](4, function(i) {
            game.setColor(_this.color);
            return game.clearOut(".oO@"[i], _this.pos);
          }, function() {
            var newpos;
            newpos = _this.pos.add(_this.newdir);
            if ((game.grid.contains(newpos)) && !game.grid.get(newpos)) {
              new Trail(_this, _this.dir, _this.newdir);
              _this.dir = _this.newdir;
              _this.pos = newpos;
              game.grid.set(_this, _this.pos);
              _this.char = "@";
            } else {
              _this.char = "X";
            }
            game.refresh(_this.pos);
            return null;
          });
        });
      }
      this.stepCont();
      return this.char === "X";
    };

    Player.prototype.draw = function() {
      game.setColor(this.color);
      return game.out(this.char, this.pos);
    };

    Player.prototype.onKeyDown = function(char) {
      var idx;
      idx = this.keyconf.indexOf(char);
      if (idx !== -1) this.newdir = Vector.dirs[idx];
      if (this.newdir.neg().eq(this.dir)) return this.newdir = this.dir;
    };

    Player.prototype.onTouchStart = function(touchStart, touchId) {
      this.touchStart = touchStart;
      this.touchId = touchId;
    };

    Player.prototype.onTouchMove = function(pos, touchId) {
      var delta, max;
      if (this.touchId !== touchId || !(this.touchStart != null)) return;
      delta = pos.sub(this.touchStart);
      if (delta.len() > 15) {
        max = Math.max(Math.abs(delta.x), Math.abs(delta.y));
        this.newdir = v(Math.trunc(delta.x / max), Math.trunc(delta.y / max));
      }
      if (this.newdir.neg().eq(this.dir)) {
        this.newdir = this.dir;
        return this.touchStart = pos;
      }
    };

    Player.tie = function(player0, player1) {
      if (player0.pos.add(player0.dir).eq(player1.pos.add(player1.dir))) {
        return true;
      } else if (player0.dir.neg().eq(player1.dir)) {
        return player0.pos.eq(player1.pos.add(player1.dir));
      } else {
        return false;
      }
    };

    return Player;

  })();

  Trail = (function() {

    function Trail(player, olddir, dir) {
      this.player = player;
      this.pos = this.player.pos;
      this.char = olddir.x === 0 && dir.x === 0 ? "|" : olddir.y === 0 && dir.y === 0 ? "-" : "+";
      game.grid.set(this, this.pos);
    }

    Trail.prototype.draw = function() {
      game.setColor(this.player.color);
      return game.out(this.char, this.pos);
    };

    return Trail;

  })();

  window.onload = function() {
    var down, el;
    el = document.getElementById("canvas");
    game.start(el);
    document.body.onkeydown = function(event) {
      return game.screen.onKeyDown(String.fromCharCode(event.keyCode));
    };
    if ("ontouchstart" in el) {
      el.ontouchstart = function(event) {
        var t, _i, _len, _ref, _results;
        event.preventDefault();
        _ref = event.changedTouches;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          t = _ref[_i];
          _results.push(game.screen.onTouchStart(v(t.pageX - el.offsetLeft, t.pageY - el.offsetTop), t.identifier));
        }
        return _results;
      };
      el.ontouchmove = function(event) {
        var t, _i, _len, _ref, _results;
        event.preventDefault();
        _ref = event.changedTouches;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          t = _ref[_i];
          _results.push(game.screen.onTouchMove(v(t.pageX - el.offsetLeft, t.pageY - el.offsetTop), t.identifier));
        }
        return _results;
      };
      return el.ontouchend = function(event) {
        return event.preventDefault();
      };
    } else {
      down = false;
      el.onmousedown = function(event) {
        game.screen.onTouchStart(v(event.pageX - el.offsetLeft, event.pageY - el.offsetTop));
        return down = true;
      };
      el.onmousemove = function(event) {
        if (down) {
          return game.screen.onTouchMove(v(event.pageX - el.offsetLeft, event.pageY - el.offsetTop));
        }
      };
      return el.onmouseup = function() {
        return down = false;
      };
    }
  };

}).call(this);
