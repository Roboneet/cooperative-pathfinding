sketch = js""" function (p5){
    alert("start!")
    var points = $points,
    edges = $edges,
    state = $s0,
    depot = 5,
    nCus = $N,
    nLoc = $l;
    function sketch(s){
        var img;
        s.setup = function (){
            s.createCanvas(640, 480)
            img = s.loadImage('./map.png')
            show()
        }

        s.draw = function (){

        }

        function show(state=null){

            s.fill(225)
            s.rect(0,0, s.width, s.height)
            s.image(img, 0, 0)
            s.fill(100)
            edges.forEach(e=>{
                if(e.a < e.b )
                    s.rect(points[e.a].x*s.width/4, points[e.a].y*s.height/4, Math.abs(points[e.a].x - points[e.b].x)*s.width/4 + 1, Math.abs(points[e.a].y - points[e.b].y)*s.height/4 + 1)
            })

            s.fill(0)
            Object.keys(points).forEach(function(key) {
                i = points[key]
                s.ellipse(i.x*s.width/4, i.y*s.height/4, 10, 10)
            });

            s.fill('#0f0')
            pd = points[depot]
            s.ellipse(pd.x*s.width/4, pd.y*s.height/4, 10, 10)

            if(!state)return

            occupancy = state[4].reduce((acc, ele)=>{
                if(!acc[ele])acc[ele] = 0;
                acc[ele] += 1
                return acc
            },{})


            Object.keys(occupancy).forEach(function(key) {
                i = occupancy[key]
                p = points[key]
                s.fill('#f00')
                s.stroke(255)
                s.ellipse(p.x*s.width/4 + 18, p.y*s.height/4 + 18, 30, 30);
                s.fill(255)
                s.textSize(22)
                s.text(i.toString(), p.x*s.width/4 + 13, p.y*s.height/4 + 27);
            });

            i = 0;
            var num = function(n, color, {ex, ey, ew, eh, tx, ty}={}){
                s.fill(color)
                s.stroke(255)
                s.ellipse(ex, ey, ew, eh);
                s.fill(255)
                s.textSize(18)
                s.text(n.toString(), tx, ty);
            }
            str = "";
            state[3].forEach((e, k)=>{
                str += Math.floor(k/nCus) + " " + k + " " + nCus + "\n";
                p = points[Math.floor(k/nCus) + 1]
                l = k%nCus
                num(e, '#00f', {
                    ex: p.x*s.width/4 - 18*(i + 1),
                    ey: p.y*s.height/4 - 18*(i + 1),
                    ew: 24,
                    eh: 24,
                    tx: p.x*s.width/4 - 13*(i + 1),
                    tx: p.y*s.height/4 - 13*(i + 1)
                })
            })

        }
        Window.show = show
    }

    var kk = (t)=>{
        var text = this.dom.querySelector('#text');
        text.innerText = t;

    }

    new p5(sketch, this.dom.querySelector('#container')) }"""
