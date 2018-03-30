///<reference path="./render-utils.js" />
///<reference path="./background.js" />
///<reference path="./man.js" />
///<reference path="./wall.js" />
///<reference path="./labyrinth.js" />
///<reference path="./canvas-renderer.js" />

"use strict";

/**
 * 
 * @param {MouseEvent} event 
 */
function onPlayfieldMouseUp(event)
{
    let [relX, relY] = calculateRanges(canvas.clientWidth, canvas.clientHeight);
    let newDest = unclip(
        event.offsetX, 
        event.offsetY, 
        canvas.clientWidth,
        canvas.clientHeight, 
        world.baseRange * relX, 
        world.baseRange * relY, 
        world.ego.x, 
        world.ego.y);

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

    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    let [relX, relY] = calculateRanges(canvas.width, canvas.height);
    var context = canvas.getContext("2d");
    renderWorld(context, canvas.width, canvas.height, world.baseRange * relX, world.baseRange * relY, world.ego.x, world.ego.y);

    requestAnimationFrame(takeStep);
}


var isAnimationRunning = false;

var world = {
    baseRange: 10,
    ego: new Man(1,0),
    background: new Background(),
    walls: new Labyrinth(20,20).getWalls()
};

/** @type {HTMLCanvasElement} */
var canvas;

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
    renderBackground(world.background, context, width, height, rangeX, rangeY, offsetX, offsetY);
    world.walls.forEach(w => renderWall(w, context, width, height, rangeX, rangeY, offsetX, offsetY));
    renderMan(world.ego, context, width, height, rangeX, rangeY, offsetX, offsetY);
}

function calculateRanges(width, height)
{
    if(width > height)
        return [1, height/width];
    else
        return [width/height, 1];
}

document.addEventListener("DOMContentLoaded", function pageInit(event){
    
    /** @type {HTMLCanvasElement} */
    canvas = document.getElementById("playfield");
    canvas.addEventListener("mouseup", onPlayfieldMouseUp);


    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    let [relX, relY] = calculateRanges(canvas.width, canvas.height);
    let context = canvas.getContext("2d");
    
    renderWorld(context, canvas.width, canvas.height, world.baseRange * relX, world.baseRange * relY, world.ego.x, world.ego.y);
});