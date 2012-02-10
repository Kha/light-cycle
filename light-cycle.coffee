class Vector
    constructor : (@x, @y) ->
    add : (v2) ->
        v @x + v2.x, @y + v2.y

v = (x, y) -> new Vector x, y

grid =
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
    constructor : (@grid) ->
        @field = ((null for y in [0..@grid.height-1]) for x in [0..@grid.width-1])
        @player = new Player this, "orange", (v 0, 10), (v 1, 0)
        @timer = setInterval () =>
            @grid.draw()
        , 200

    draw : (ctx) ->
        @player.draw ctx

    stop : () -> clearInterval @timer

class Player
    constructor : (@game, @color, @pos, @dir) ->

    draw : (ctx) ->
        @game.grid.setColor @color

        newpos = @pos.add @dir
        if newpos.x >= @game.grid.width-1
            @game.grid.out "X", @pos.x, @pos.y
            @game.stop()
        else 
            @pos = newpos
            @game.grid.out "@", @pos.x, @pos.y
        
window.onload = ->
    grid.start (document.getElementById "canvas")
