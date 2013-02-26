Math.trunc = (x) ->
    if x > 0
        Math.floor x
    else
        Math.ceil x

Array::any = (f) -> not this.every (x) -> not(f x)

class Vector
    constructor : (@x, @y) ->
    add : (v2) -> v @x + v2.x, @y + v2.y
    sub : (v2) -> @add(v2.neg())
    neg : -> v -@x, -@y
    eq : (v2) -> @x == v2.x and @y == v2.y
    len : -> Math.sqrt @x*@x+@y*@y

    @dirs : [new Vector(1, 0), new Vector(0, 1), new Vector(-1, 0), new Vector(0, -1)]

v = (x, y) -> new Vector x, y

class Grid
    constructor : (@width, @height) ->
        @grid = ((null for y in [0..@height-1]) for x in [0..@width-1])

    get : (pos) ->
        return @grid[pos.x][pos.y] if @contains pos
        null

    all : -> [].concat @grid...

    set : (x, pos) ->
        @grid[pos.x][pos.y] = x if @contains pos

    move : (p1, p2) ->
        @set (@get p1), p2
        @set null, p1

    contains : (pos) -> 0 <= pos.x < @width and 0 <= pos.y < @height

cps =
    create : (f) ->
        cont = f
        ->  
            next = cont()
            if next? then cont = next

    wait : (ticks, cont) -> cps.for ticks, (->), cont

    for : (ticks, loopBody, cont) ->
        rec = (i) ->
            if i == ticks
                cont
            else
                ->
                    loopBody i
                    rec i+1, loopBody, cont
        rec 0


game =
    dx : 23
    dy : 23

    setColor : (color) ->
        @ctx.fillStyle = @ctx.shadowColor = color

    out : (char, pos) -> @ctx.fillText char, pos.x*@dx, pos.y*@dy

    clearOut : (char, pos) ->
        @clear pos, 1, 1
        @out char, pos

    clear : (pos, w, h) ->
        fillStyle = @ctx.fillStyle
        @ctx.fillStyle = "black"
        @ctx.shadowBlur = 0
        @ctx.fillRect pos.x*@dx, pos.y*@dy, w*@dx, h*@dy
        @ctx.shadowBlur = 4
        @ctx.fillStyle = fillStyle

    setScreen : (screenGetter) ->
        # draw grid before instantiating screen
        @grid = new Grid @width, @height
        @clear (v 0, 0), @width, @height
        @createBorder()

        @screen = screenGetter()
        @step = cps.create => @screen.step()

    start : (canvas) ->
        if not (@ctx = canvas.getContext "2d") then return

        @width = Math.floor(window.innerWidth / @dx) - 1
        @height = Math.floor(window.innerHeight / @dy) - 1

        canvas.width = @width * @dx
        canvas.height = @height * @dy
        @ctx.font          = "20px monospace"
        @ctx.textBaseline  = "top"
        @ctx.shadowBlur    = 4

        @setScreen => new Menu()
        @timer =
            setInterval (=> @step()), 200

    createBorder : ->
        for x in [1..@width-2]
            new Char "-", (v x, 0)
            new Char "-", (v x, @height-1)
        for y in [1..@height-2]
            new Char "|", (v 0, y)
            new Char "|", (v @width-1, y)
        new Char "+", (v 0, 0)
        new Char "+", (v @width-1, 0)
        new Char "+", (v 0, @height-1)
        new Char "+", (v @width-1, @height-1)

    refresh : (pos) ->
        @clear (pos.sub (v 2, 2)), 5, 5
        for x in [pos.x-2..pos.x+2]
            for y in [pos.y-2..pos.y+2]
                @grid.get(v x, y)?.draw()

    stop : () -> clearInterval @timer

class Char
    constructor : (@char, @pos, angle, color) ->
        @angle = angle ? 0
        @color = color ? "white"
        game.grid.set this, @pos
        @draw()

    draw : ->
        game.ctx.save()
        game.setColor @color
        game.ctx.translate game.dx * @pos.x, game.dy * @pos.y
        game.ctx.rotate @angle * Math.PI/2
        game.clearOut @char, (v 0,0)
        game.ctx.restore()

    @drawString : (string, pos, angle, color) ->
        angle ?= 0
        delta = Vector.dirs[angle]
        if pos.x == -1
            pos = v Math.floor((game.grid.width - string.length * delta.x)/2), pos.y
        if pos.y == -1
            pos = v pos.x, Math.floor((game.grid.height - string.length * delta.y)/2)

        chars = []
        for c in string
            chars.push new Char c, pos, angle, color
            pos = pos.add delta
        chars

#{{{ screens

class Menu
    constructor : ->
        @start = Char.drawString "Start!", (v -1, Math.floor(game.height/2)-1)
        @help = Char.drawString "Help!", (v -1, Math.floor(game.height/2)+1)
        Char.drawString "Player 1", (v 3, -1), 1, "orange"
        Char.drawString "Player 2", (v game.width-1 - 3, -1), 3, "cornflowerblue"

    step : -> null

    onKeyDown : (char) ->
        if char == "\r"
            game.setScreen => new Match()

    onTouchStart : (pos) ->
        pos = v Math.floor(pos.x/game.dx), Math.floor(pos.y/game.dy)
        if @start.any ((c) -> c.pos.eq pos)
            game.setScreen => new Match()
        else if @help.any ((c) -> c.pos.eq pos)
            game.setScreen => new Help()

class Help
    constructor : ->
        text = """
Maneuver your light cycle
quickly and precisely to
make your opponents's cycle
crash into the wall or your
cycle's light trail! The
first player to score 15
points wins the game. Swipe
your finger to change your
cycle's direction but don't
forget to start the swipe in
your respective half of the
game field. If your device
has a physical keyboard, the
first player can also use
keys WASD, the second one
IJKL."""
        for line, i in text.split '\n'
            Char.drawString line, (v -1, i+5)

        @roger = Char.drawString "Roger!", (v -1, game.height-1 - 3)

    step : -> null

    onTouchStart : (pos) ->
        pos = v Math.floor(pos.x/game.dx), Math.floor(pos.y/game.dy)
        if @roger.any ((c) -> c.pos.eq pos)
            game.setScreen => new Menu()

class Match
    constructor : ->
        @score0 = @score1 = 0
        @initPoint()

    initPoint : ->
        halfHeight = Math.floor((game.grid.height-1)/2)
        @player0 = new Player "orange", "DSAW", v(3, halfHeight), v(1, 0)
        @player1 = new Player "cornflowerblue", "LKJI", v(game.grid.width-1 - 3, halfHeight), v(-1, 0)

        @updateScore()
        @back = Char.drawString "Back", (v -1, game.grid.height-1)

    updateScore : ->
        Char.drawString @score0 + " : " + @score1, (v -1, 0)

    step : ->
        if Player.tie(@player0, @player1)
            @score0++
            @score1++
        else if @player0.step()
            @score1++
        else if @player1.step()
            @score0++
        else
            return null

        @updateScore()
        if Math.max(@score0, @score1) == 15
            return cps.wait 10, => game.setScreen -> new Menu()

        cps.wait 5, =>
            @initPoint()
            game.setScreen => this
            @updateScore()

    onKeyDown : (char) ->
        @player0.onKeyDown char
        @player1.onKeyDown char

    onTouchStart : (pos, identifier) ->
        pos2 = v Math.floor(pos.x/game.dx), Math.floor(pos.y/game.dy)
        if @back.any ((c) -> c.pos.eq pos2)
            return game.setScreen => new Menu()

        if pos.x / game.dx < game.width / 2
            @player0.onTouchStart pos, identifier
        else
            @player1.onTouchStart pos, identifier

    onTouchMove : (pos, identifier) ->
        @player0.onTouchMove pos, identifier
        @player1.onTouchMove pos, identifier

    onTouchEnd : (identifier) ->
        @player0.onTouchEnd identifier
        @player1.onTouchEnd identifier

class Player
    score : 0
    score2: @score

    constructor : (@color, @keyconf, @pos, @dir) ->
        game.grid.set this, @pos
        @newdir = @dir

    step : ->
        @stepCont ?= cps.create =>
            cps.for 4, (i) =>
                game.setColor @color
                game.clearOut ".oO@"[i], @pos
            , =>
                newpos = @pos.add @newdir
                if (game.grid.contains newpos) and not game.grid.get newpos
                    new Trail this, @dir, @newdir
                    @dir = @newdir
                    @pos = newpos
                    game.grid.set this, @pos
                    @char = "@"
                else
                    @char = "X"
                game.refresh @pos
                null

        @stepCont()
        @char == "X"

    draw : ->
        game.setColor @color
        game.out @char, @pos

    onKeyDown : (char) ->
        idx = @keyconf.indexOf char
        if idx != -1
            @newdir = Vector.dirs[idx]
        if @newdir.neg().eq @dir
            @newdir = @dir

    onTouchStart : (@touchStart, @touchId) ->

    onTouchMove : (pos, touchId) ->
        if @touchId != touchId or not @touchStart? then return

        delta = pos.sub @touchStart
        if delta.len() > 15
            max = Math.max Math.abs(delta.x), Math.abs(delta.y)
            @newdir = v Math.trunc(delta.x / max), Math.trunc(delta.y / max)
        if @newdir.neg().eq @dir
            @newdir = @dir
            @touchStart = pos

    onTouchEnd : (touchId) ->
        if @touchId == touchId
            @touchStart = null

    @tie : (player0, player1) ->
        if player0.pos.add(player0.dir).eq player1.pos.add(player1.dir)
            true
        # head-on collision?
        else if player0.dir.neg().eq player1.dir
            player0.pos.eq player1.pos.add(player1.dir)
        else
            false

class Trail
    constructor : (@player, olddir, dir) ->
        @pos = @player.pos
        @char =
            if olddir.x == 0 and dir.x == 0 then "|"
            else if olddir.y == 0 and dir.y == 0 then "-"
            else "+"
        game.grid.set this, @pos

    draw : ->
        game.setColor @player.color
        game.out @char, @pos

#}}}

window.onload = ->
    el = document.getElementById "canvas"
    game.start el
    document.body.onkeydown = (event) ->
        game.screen.onKeyDown (String.fromCharCode event.keyCode)
    if "ontouchstart" of el
        el.ontouchstart = (event) ->
            event.preventDefault()
            for t in event.changedTouches
                game.screen.onTouchStart v(t.pageX - el.offsetLeft, t.pageY - el.offsetTop), t.identifier
        el.ontouchmove = (event) ->
            event.preventDefault()
            for t in event.changedTouches
                game.screen.onTouchMove v(t.pageX - el.offsetLeft, t.pageY - el.offsetTop), t.identifier
        el.ontouchend = (event) ->
            event.preventDefault()
            for t in event.changedTouches
                game.screen.onTouchEnd t.identifier
    else
        down = false
        el.onmousedown = (event) ->
            game.screen.onTouchStart v(event.pageX - el.offsetLeft, event.pageY - el.offsetTop)
        el.onmousemove = (event) ->
            game.screen.onTouchMove v(event.pageX - el.offsetLeft, event.pageY - el.offsetTop)
        el.onmouseup = -> game.screen.onTouchEnd undefined
