Math.trunc = (x) ->
    if x > 0
        Math.floor x
    else
        Math.ceil x

class Vector
    constructor : (@x, @y) ->
    add : (v2) -> v @x + v2.x, @y + v2.y
    sub : (v2) -> @add(v2.neg())
    neg : -> v -@x, -@y
    eq : (v2) -> @x == v2.x and @y == v2.y
    len : -> Math.sqrt @x*@x+@y*@y

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
    width : 31
    height : 31
    dx : 16
    dy : 16

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
        @ctx.font          = "14px monospace"
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

class Match
    constructor : ->
        @score0 = @score1 = 0
        @initPoint()

    initPoint : ->
        halfHeight = Math.floor((game.grid.height-1)/2)
        @player0 = new Player "orange", "WASD", v(3, halfHeight), v(1, 0)
        @player1 = new Player "cornflowerblue", "IJKL", v(game.grid.width-1 - 3, halfHeight), v(-1, 0)

        @updateScore()

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

    onTouchStart : (pos) ->
        if pos.x / @dx < @width / 2
            @player0.onTouchStart pos
        else
            @player1.onTouchStart pos

    onTouchMove : (pos) ->
        if pos.x / @dx < @width / 2
            @player0.onTouchMove pos
        else
            @player1.onTouchMove pos

class Menu
    constructor : ->
        Char.drawString "Press Enter to start!", (v -1, -1)

    step : -> null

    onKeyDown : (char) ->
        if char == "\r"
            game.setScreen => new Match()

class Char
    constructor : (@char, @pos) ->
        game.grid.set this, @pos
        @draw()

    draw : ->
        game.setColor "white"
        game.clearOut @char, @pos

    @drawString : (string, pos) ->
        if pos.x == -1
            pos = v Math.floor((game.grid.width - string.length)/2), pos.y
        if pos.y == -1
            pos = v pos.x, Math.floor(game.grid.height/2)

        for i in [0..string.length-1]
            new Char string[i], pos.add(v i, 0)

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
            @newdir = [v(0, -1), v(-1, 0), v(0,1), v(1, 0)][idx]
        if @newdir.neg().eq @dir
            @newdir = @dir

    onTouchStart : (@touchStart) ->

    onTouchMove : (pos) ->
        delta = pos.sub @touchStart
        if delta.len() > 15
            max = Math.max Math.abs(delta.x), Math.abs(delta.y)
            @newdir = v Math.trunc(delta.x / max), Math.trunc(delta.y / max)
        if @newdir.neg().eq @dir
            @newdir = @dir
            @touchStart = pos

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

window.onload = ->
    el = document.getElementById "canvas"
    game.start el
    document.body.onkeydown = (event) ->
        game.screen.onKeyDown (String.fromCharCode event.keyCode)
    if "ontouchstart" of el
        el.ontouchstart = (event) ->
            event.preventDefault()
            for t in event.changedTouches
                game.screen.onTouchStart v(t.pageX - el.offsetLeft, t.pageY - el.offsetTop)
        el.ontouchmove = (event) ->
            event.preventDefault()
            for t in event.changedTouches
                game.screen.onTouchMove v(t.pageX - el.offsetLeft, t.pageY - el.offsetTop)
        el.ontouchend = (event) ->
            event.preventDefault()
    else
        down = false
        el.onmousedown = (event) ->
                game.screen.onTouchStart v(event.pageX - el.offsetLeft, event.pageY - el.offsetTop)
                down = true
        el.onmousemove = (event) ->
                if down
                    game.screen.onTouchMove v(event.pageX - el.offsetLeft, event.pageY - el.offsetTop)
        el.onmouseup = -> down = false
