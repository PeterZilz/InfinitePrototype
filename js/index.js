///<reference path="background.js" />
///<reference path="man.js" />

"use strict";

function onCanvasResize(event)
{
    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.style.height = Math.floor(canvas.clientWidth / 2)+"px";
}

/**
 * 
 * @param {MouseEvent} event 
 */
function onPlayfieldMouseUp(event)
{

    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");

    let newDest = unclip(event.offsetX, event.offsetY, canvas.clientWidth,canvas.clientHeight, 10, 5, world.ego.x, world.ego.y);

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

    let previousPosition = [world.ego.x, world.ego.y];

    world.ego.stepTowardsDestination();

    // validate current position. 
    // Technically checking only the bounding box is not correct.
    // But for the Labyrinth it works.
    if(world.walls.some(w => w.isInsideBoundingBox(world.ego.x, world.ego.y))){
        // If invalid delete destination 
        // and reset to previous position
        // and stop animation.
        world.ego.destination = null;
        world.ego.x = previousPosition[0];
        world.ego.y = previousPosition[1];
        isAnimationRunning = false;
        return;
    }

    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.width = canvas.clientWidth;
    if(canvas.clientWidth % 2 == 1)
        canvas.width--;
    canvas.style.height = Math.floor(canvas.width / 2)+"px";
    canvas.height = Math.floor(canvas.width / 2);
    var context = canvas.getContext("2d");
    renderWorld(context, canvas.width, canvas.height, 10, 5, world.ego.x, world.ego.y);

    requestAnimationFrame(takeStep);
}


var isAnimationRunning = false;

var world = {
    ego: new Man(0,0),
    background: new Background(),
    walls: new Labyrinth(20,20).getWalls()
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
    if(canvas.clientWidth % 2 == 1)
        canvas.width--;
    canvas.style.height = Math.floor(canvas.width / 2)+"px";
    canvas.height = Math.floor(canvas.width / 2);
    var context = canvas.getContext("2d");
    
    renderWorld(context, canvas.width, canvas.height, 10, 5, 0, 0);
});