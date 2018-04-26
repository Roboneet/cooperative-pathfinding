blinkWindow = Blink.Window()

w = Scope(imports=["//cdnjs.cloudflare.com/ajax/libs/p5.js/0.5.11/p5.js"])
struct Vehicle
    status
    loc
    dest
end

struct Req
    loc
    from
    to
end

struct Point
    index
    x
    y
end

struct Edge
    a
    b
end

points = Dict()
edges = []

for (v, e) in graph
  y = Int(floor((v - 1)/3) + 1)
  x = (v-1)%3 + 1
  points[v] = Point(v, x, y)
  for i in e
      push!(edges, Edge(v, i))
  end
end

s0 = VRPState0()
d = Observable(w, "state", s0)

function draw(env::VRP, s::sType, a::Array{Int64, 1}, r::Array{Int64}, s′::sType)
    d[] = s
end

include("sketch.jl")
onimport(w, sketch)

w(dom"div#main"(dom"div#text"("hjksdbashd"),dom"div#container"()))

onjs(d, JSExpr.@js (state) -> begin
    Window.show(state)
end)

render(w)

body!(blinkWindow, w)
