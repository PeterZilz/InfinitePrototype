"use strict";

function onCanvasResize(event)
{
    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.style.height = (canvas.clientWidth / 2)+"px";
}

/**
 * 
 * @param {MouseEvent} event 
 */
function onPlayfieldMouseUp(event)
{

    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");

    let newDest = unclip(event.offsetX, event.offsetY, canvas.clientWidth,canvas.clientHeight, 10, 5, 0, 0);

    world.ego.destination = newDest;

    if(!isAnimationRunning){
        isAnimationRunning = true;
        requestAnimationFrame(takeStep);
    }
}


function takeStep()
{
    if(world.ego.destination == null)
    {
        isAnimationRunning = false;
        return;
    }

    world.ego.stepTowardsDestination();

    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.width = canvas.clientWidth;
    canvas.style.height = (canvas.clientWidth / 2)+"px";
    canvas.height = canvas.clientWidth / 2;
    var context = canvas.getContext("2d");
    renderWorld(context, canvas.width, canvas.height, 10, 5, 0, 0);

    requestAnimationFrame(takeStep);
}


var isAnimationRunning = false;

var world = {
    ego: new Man(0,0),
    background: new Background(),
    walls: [
        new Wall([
            [-0.8,2],
            [-4,2],
            [-4,-2],
            [4,-2],
            [4,2],
            [0.8,2],
            [0.8,1.5],
            [3.5,1.5],
            [3.5,-1.5],
            [-3.5,-1.5],
            [-3.5,1.5],
            [-0.8,1.5]
        ])
    ]
};

/**
 * Renders the all things on the given context.
 * @param {CanvasRenderingContext2D} context pane to render to
 * @param {number} width width in pixels
 * @param {number} height height in pixels
 * @param {number} rangeX width in coordinates
 * @param {number} rangeY height in coordinates
 * @param {number} offsetX x-coordinate of the center of the image
 * @param {number} offsetY y-coordinate of the center of the image
 */
function renderWorld(context, width, height, rangeX, rangeY, offsetX, offsetY){
    world.background.render(context, width, height, rangeX, rangeY, offsetX, offsetY);
    world.walls.forEach(w => w.render(context, width, height, rangeX, rangeY, offsetX, offsetY));
    world.ego.render(context, width, height, rangeX, rangeY, offsetX, offsetY);
}

document.addEventListener("DOMContentLoaded", function pageInit(event){

    window.addEventListener("resize", onCanvasResize);
    
    onCanvasResize(null);
    
    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.addEventListener("mouseup", onPlayfieldMouseUp);


    canvas.width = canvas.clientWidth;
    canvas.style.height = (canvas.clientWidth / 2)+"px";
    canvas.height = canvas.clientWidth / 2;
    var context = canvas.getContext("2d");
    
    renderWorld(context, canvas.width, canvas.height, 10, 5, 0, 0);
});