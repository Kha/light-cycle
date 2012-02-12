class Vector
    constructor : (@x, @y) ->
    add : (v2) -> v @x + v2.x, @y + v2.y
    sub : (v2) -> @add(v2.neg())
    neg : -> v -@x, -@y
    eq : (v2) -> @x == v2.x and @y == v2.y

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
    wait : (ticks, cont) ->
        if ticks == 0
            cont
        else
            -> cps.wait ticks-1, cont

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

    start : (canvas) ->
        if not (@ctx = canvas.getContext "2d") then return

        @width = Math.floor(window.innerWidth / @dx) - 1
        @height = Math.floor(window.innerHeight / @dy) - 1

        canvas.width = @width * @dx
        canvas.height = @height * @dy
        @ctx.font          = "14px monospace"
        @ctx.textBaseline  = "top"
        @ctx.shadowBlur    = 4

        cont = @initPlay
        _this = this
        @timer = setInterval () ->
            if next = cont.call _this
                cont = next
        , 100

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

    updateScore : ->
        Char.drawString @player0.score + " : " + @player1.score, (v -1, 0)
        
    initPlay : ->
        @grid = new Grid @width, @height

        halfHeight = Math.floor((@grid.height-1)/2)
        @player0 ?= new Player "orange", "WASD"
        @player0.init v(3, halfHeight), v(1, 0)

        @player1 ?= new Player "cornflowerblue", "IJKL"
        @player1.init v(@grid.width-1 - 3, halfHeight), v(-1, 0)

        @clear (v 0, 0), @width, @height
        @createBorder()
        @updateScore()

        @step

    step : ->
        if Player.tie(@player0, @player1)
            @player0.score++
            @player1.score++
        else if @player0.step()
            @player1.score++
        else if @player1.step()
            @player0.score++
        else
            return null

        @updateScore()
        cps.wait 5, @initPlay

    refresh : (pos) ->
        @clear (pos.sub (v 2, 2)), 5, 5
        for x in [pos.x-2..pos.x+2]
            for y in [pos.y-2..pos.y+2]
                @grid.get(v x, y)?.draw()

    stop : () -> clearInterval @timer

    onKeyDown : (char) ->
        @player0.onKeyDown char
        @player1.onKeyDown char

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
        for i in [0..string.length-1]
            new Char string[i], pos.add(v i, 0)

class Player
    score : 0

    constructor : (@color, @keyconf) ->

    init : (@pos, @dir) ->
        game.grid.set this, @pos
        @newdir = @dir

    step : ->
        newpos = @pos.add @newdir
        if (game.grid.contains newpos) and not game.grid.get newpos
            new Trail this, @dir, @newdir
            @dir = @newdir
            @pos = newpos
            game.grid.set this, @pos
            @char = "@"
            game.refresh @pos
            0
        else
            @char = "X"
            game.refresh @pos
            1

    draw : ->
        game.setColor @color
        game.out @char, @pos

    onKeyDown : (char) ->
        idx = @keyconf.indexOf char
        if idx != -1
            @newdir = [v(0, -1), v(-1, 0), v(0,1), v(1, 0)][idx]
        if @newdir.neg().eq @dir
            @newdir = @dir

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
    document.body.onkeydown = (event) -> game.onKeyDown (String.fromCharCode event.keyCode)
