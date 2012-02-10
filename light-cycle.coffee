class Vector
    constructor : (@x, @y) ->
    add : (v2) ->
        v @x + v2.x, @y + v2.y

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
    width : 40
    height : 20

    setColor : (color) ->
        @ctx.fillStyle = @ctx.shadowColor = color
    out : (char, x, y) -> @ctx.fillText char, x*@dx, y*@dy

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

    draw: ->
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

        @game.draw @ctx

class Game
    constructor : (@canvas) ->
        @grid = new Grid @canvas.width-2, @canvas.height-2
        @player = new Player this, "orange", (v 3, 9), (v 1, 0)
        @timer = setInterval () =>
            @canvas.draw()
        , 200

    draw : (ctx) ->
        ctx.save()
        ctx.translate @canvas.dx, @canvas.dy
        for sprite in @grid.all() when sprite
            sprite.draw ctx
        ctx.restore()

    stop : () -> clearInterval @timer

class Player
    constructor : (@game, @color, @pos, @dir) ->
        @game.grid.set this, @pos

    draw : (ctx) ->
        @game.canvas.setColor @color

        newpos = @pos.add @dir
        if @game.grid.contains newpos
            (new Trail this).draw ctx
            @pos = newpos
            @game.grid.set this, @pos
            @game.canvas.out "@", @pos.x, @pos.y
        else 
            @game.canvas.out "X", @pos.x, @pos.y
            @game.stop()
        
class Trail
    constructor : (@player) ->
        @pos = @player.pos
        @char = "-"
        @player.game.grid.set this, @pos

    draw : (ctx) ->
        @player.game.canvas.setColor @player.color
        @player.game.canvas.out @char, @pos.x, @pos.y
 
window.onload = ->
    canvas.start (document.getElementById "canvas")
