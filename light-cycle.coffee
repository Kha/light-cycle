start = ->
    canvas = document.getElementById "canvas"
    if not (ctx = canvas.getContext "2d") then return
    ctx.font = "14px monospace"
    dx = (ctx.measureText "+").width
    dy = 16
    width = 40
    height = 20
    canvas.width = width * dx
    canvas.height = height * dy

    ctx.fillRect 0, 0, canvas.width, canvas.height
    ctx.font = "14px monospace"
    ctx.fillStyle = "white"
    ctx.textBaseline = "top"
    ctx.shadowBlur    = 4
    ctx.shadowColor   = "white"

    out = (char, x, y) -> ctx.fillText char, x*dx, y*dy
    for x in [1..width-2]
        out "-", x, 0
        out "-", x, height-1
    for y in [1..height-2]
        out "|", 0, y
        out "|", width-1, y
    out "+", 0, 0
    out "+", width-1, 0
    out "+", 0, height-1
    out "+", width-1, height-1

window.onload = start
