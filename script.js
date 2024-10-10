const socket = new WebSocket("ws:127.0.0.1:8080");
socket.onopen = (event) => {
    console.log("Socket connected")
};
socket.onclose = () => {
    console.log("WebSocket connection closed");
}

class Vec2 {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}



class Circle {
    constructor(pos, r) {
        this.x = pos.x;
        this.y = pos.y;
        this.r = r;
    }

    draw() {
        fill(255)
        circle(this.x, this.y, this.r * 2)
    }
}

class Rectangle {
    constructor(pos, size) {
        console.log(pos)
        console.log(size)
        this.x = pos.x;
        this.y = pos.y;
        this.w = size.x;
        this.h = size.y;
    }

    draw() {
        fill(255)
        rect(this.x, this.y, this.w, this.h)
    }
}



const Shapes = {
    Circle: "Circle",
    Rectangle: "Rectangle",
}

class Renderable {
    constructor({ shape = "" }) {
        this.isStatic = false


        switch (shape) {
            case Shapes.Circle: { this.shape = new Circle(new Vec2(100, 200), 20); break; }
            case Shapes.Rectangle: { this.shape = new Rectangle(new Vec2(200, 200), new Vec2(100, 100)); break; }
            // default: { this.shape = new Circle(100, 100, 20); break; }
        }
    }

    static get(shape) {
        var ren = new Renderable({});
        ren.shape = shape
        return ren
    }

    setPos(x, y) {
        this.shape.x = x
        this.shape.y = y

    }
}

function createRenderableObject(shapeData) {
    const shapeType = Object.keys(shapeData.rObj)[0]
    const shape = shapeData.rObj[shapeType];
    // switch (shapeType) {
    //     case Shapes.Circle: return new Circle(shape.pos, shape.rad);
    //     case Shapes.Rectangle: return new Rectangle(shape.pos, shape.size);
    // }

    switch (shapeType) {
        case Shapes.Circle: return Renderable.get(new Circle(shape.pos, shape.rad));
        case Shapes.Rectangle: return Renderable.get(new Rectangle(shape.pos, shape.size));
    }
}


var render_objs = []


function setup() {
    createCanvas(800, 600);



}
var a = undefined

socket.onmessage = (event) => {
    const d = JSON.parse(event.data)
    a = d
    // if (d.name == "move") {
    //     p.x = d.val
    // }

    // if (d.name == "create") {
    //     render_objs.push(new Renderable({ shape: d.val }))
    // }

    if (d.name == "create_obj") {
        const obj = new createRenderableObject(d)
        render_objs.push(obj)

        console.log(render_objs)
    }
}

var mouse_down = false

function mousePressed(event) {
    // render_objs.forEach(obj => {
    //     if(!obj.isStatic){
    //         obj.setPos(mouseX, mouseY)
    //     }

    // });

    mouseButton = LEFT
    mouse_down = true
}

function mouseReleased() {
    mouseButton = 0
    mouse_down = false
    console.log("released")
}

function mouseMove() {
    // if(mouseButton !== LEFT) return
    if(mouse_down === false) return

    render_objs.forEach(obj => {
        if(!obj.isStatic){
            dx = obj.shape.x - mouseX
            dy = obj.shape.y - mouseY

            dest = Math.sqrt(dx * dx + dy * dy);

            console.log(dest)

            if(dest < 50) {
                obj.setPos(mouseX, mouseY)
            }

        }

    });
}

function draw() {
    background(60)

    render_objs.forEach(obj => {
        obj.shape.draw()
    });

    mouseMove()



    // rect(400, 300, 100, 100)
}