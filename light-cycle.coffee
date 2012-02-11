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

canvas =
    width : 60
    height : 30

    setColor : (color) ->
        @ctx.fillStyle = @ctx.shadowColor = color

    out : (char, x, y) -> @ctx.fillText char, x*@dx, y*@dy

    clear : (pos, w, h) ->
        @ctx.fillStyle = "black"
        @ctx.shadowBlur = 0
        @ctx.fillRect pos.x*@dx, pos.y*@dy, w*@dx, h*@dy
        @ctx.shadowBlur = 4

    start : (canvas) ->
        if not (@ctx = canvas.getContext "2d") then return
        @ctx.font = "14px monospace"
        @dx = (@ctx.measureText "+").width
        @dy = 16
        canvas.width = @width * @dx
        canvas.height = @height * @dy
        @ctx.font          = "14px monospace"
        @ctx.textBaseline  = "top"
        @ctx.shadowBlur    = 4

        @game = new Game this

        @setColor "black"
        @ctx.fillRect 0, 0, @width*@dx, @height*@dy
        @setColor "white"

        for x in [1..@width-2]
            @out "-", x, 0
            @out "-", x, @height-1
        for y in [1..@height-2]
            @out "|", 0, y
            @out "|", @width-1, y
        @out "+", 0, 0
        @out "+", @width-1, 0
        @out "+", 0, @height-1
        @out "+", @width-1, @height-1

        @ctx.translate @dx, @dy

class Game
    constructor : (@canvas) ->
        @grid = new Grid @canvas.width-2, @canvas.height-2
        @player0 = new Player this, "orange", "WASD", (v 3, @grid.height/2), (v 1, 0)
        @player1 = new Player this, "cornflowerblue", "IJKL", (v @grid.width - 3, @grid.height/2), (v -1, 0)
        @timer = setInterval () =>
            @step()
        , 100

    step : ->
        @player0.step()
        @player1.step()

    refresh : (pos) ->
        @canvas.clear (pos.sub (v 2, 2)), 5, 5
        for x in [pos.x-2..pos.x+2]
            for y in [pos.y-2..pos.y+2]
                @grid.get(v x, y)?.draw()

    stop : () -> clearInterval @timer

    onKeyDown : (char) ->
        @player0.onKeyDown char
        @player1.onKeyDown char

class Player
    constructor : (@game, @color, @keyconf, @pos, @dir) ->
        @game.grid.set this, @pos
        @newdir = @dir

    step : ->
        newpos = @pos.add @newdir
        if (@game.grid.contains newpos) and not @game.grid.get newpos
            new Trail this, @dir, @newdir
            @dir = @newdir
            @pos = newpos
            @game.grid.set this, @pos
            @char = "@"
        else
            @char = "X"
            @game.stop()

        @game.refresh @pos

    draw : () ->
        @game.canvas.setColor @color

        @game.canvas.out @char, @pos.x, @pos.y

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
        @player.game.grid.set this, @pos

    draw : () ->
        @player.game.canvas.setColor @player.color
        @player.game.canvas.out @char, @pos.x, @pos.y

window.onload = ->
    el = document.getElementById "canvas"
    canvas.start el
    document.body.onkeydown = (event) -> canvas.game.onKeyDown (String.fromCharCode event.keyCode)
