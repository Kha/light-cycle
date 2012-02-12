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

game =
    width : 30
    height : 30
    dx : 16
    dy : 16

    setColor : (color) ->
        @ctx.fillStyle = @ctx.shadowColor = color

    out : (char, pos) -> @ctx.fillText char, pos.x*@dx, pos.y*@dy

    clearOut : (char, pos) ->
        @clear pos, 1, 1
        @out char, pos

    clear : (pos, w, h) ->
        @ctx.fillStyle = "black"
        @ctx.shadowBlur = 0
        @ctx.fillRect pos.x*@dx, pos.y*@dy, w*@dx, h*@dy
        @ctx.shadowBlur = 4

    start : (canvas) ->
        if not (@ctx = canvas.getContext "2d") then return

        @grid = new Grid @width-2, @height-2
        halfHeight = Math.floor((@grid.height-1)/2)
        @player0 = new Player "orange", "WASD", (v 3, halfHeight), (v 1, 0)
        @player1 = new Player "cornflowerblue", "IJKL", (v @grid.width-2 - 3, halfHeight), (v -1, 0)

        canvas.width = @width * @dx
        canvas.height = @height * @dy
        @ctx.font          = "14px monospace"
        @ctx.textBaseline  = "top"
        @ctx.shadowBlur    = 4

        @setColor "black"
        @ctx.fillRect 0, 0, @width*@dx, @height*@dy

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

        @timer = setInterval () =>
            @step()
        , 100

    step : ->
        @player0.step()
        @player1.step()

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
        game.out @char, @pos

class Player
    constructor : (@color, @keyconf, @pos, @dir) ->
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
        else
            @char = "X"
            game.stop()

        game.refresh @pos

    draw : ->
        game.setColor @color
        game.out @char, @pos

    onKeyDown : (char) ->
        idx = @keyconf.indexOf char
        if idx != -1
            @newdir = [v(0, -1), v(-1, 0), v(0,1), v(1, 0)][idx]
        if @newdir.neg().eq @dir
            @newdir = @dir

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
