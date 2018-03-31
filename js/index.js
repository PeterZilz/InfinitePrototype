///<reference path="./render-utils.js" />
///<reference path="./background.js" />
///<reference path="./man.js" />
///<reference path="./wall.js" />
///<reference path="./labyrinth.js" />
///<reference path="./action-panel.js" />
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
    if(!isGhostActive && world.walls.some(w => w.isInsideBoundingBox(world.ego.x, world.ego.y))){
        // If invalid delete destination 
        // and reset to previous position
        // and stop animation.
        world.ego.destination = null;
        world.ego.x = previousPosition[0];
        world.ego.y = previousPosition[1];
        isAnimationRunning = false;
        return;
    }

    let activated = world.actionPanels.filter(a => a.isActive===true && a.isInsideBoundingBox(world.ego.x, world.ego.y));
    if(activated.length > 0)
    {
        activated.forEach(a => a.doAction());
        updateScore();
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
    /** @type {Wall[]} */
    walls: null,
    /** @type {ActionPanel[]} */
    actionPanels: null,
    score: 0
};

/** @type {HTMLCanvasElement} */
var canvas;
/** @type {HTMLSpanElement} */
var spnScore;
var isGhostActive = false;
/** @type {HTMLInputElement} */
var btnGhost;

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
    world.actionPanels.filter(a=>a.isActive===true).forEach(a => renderWall(a, context, width, height, rangeX, rangeY, offsetX, offsetY));
    renderMan(world.ego, context, width, height, rangeX, rangeY, offsetX, offsetY);
}

function calculateRanges(width, height)
{
    if(width > height)
        return [1, height/width];
    else
        return [width/height, 1];
}


function doAction()
{
    this.isActive = false;
    world.score++;
}

function updateScore()
{
    spnScore.classList.remove("animCounterIncrease");
    spnScore.innerText = Math.round(world.score) + "";
    // Removing and adding the animation class is not enough.
    // Without the following line it would have no effect.
    void spnScore.offsetWidth;
    spnScore.classList.add("animCounterIncrease");
}

/**
 * Enables or disables the ghost button.
 * @param {boolean} enabled state of the ghost button
 */
function enableGhost(enabled)
{
    btnGhost.disabled = !enabled;
}

function startGhost()
{
    isGhostActive = true;
    // change color of walls
    world.walls.forEach(w => w.color = "#EEEEEE30");
    // render if not in animation
    if(!isAnimationRunning)
    {
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;
        let [relX, relY] = calculateRanges(canvas.width, canvas.height);
        var context = canvas.getContext("2d");
        renderWorld(context, canvas.width, canvas.height, world.baseRange * relX, world.baseRange * relY, world.ego.x, world.ego.y);
    }
}
function endGhost()
{
    isGhostActive = false;
    // change color of walls
    world.walls.forEach(w => w.color = "#101010");
    // render if not in animation
    if(!isAnimationRunning)
    {
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;
        let [relX, relY] = calculateRanges(canvas.width, canvas.height);
        var context = canvas.getContext("2d");
        renderWorld(context, canvas.width, canvas.height, world.baseRange * relX, world.baseRange * relY, world.ego.x, world.ego.y);
    }
}

function onclickGhost(event)
{
    if(btnGhost.disabled) return;
    enableGhost(false);
    startGhost();
    setTimeout(endGhost, 2000);
    setTimeout(() => enableGhost(true), 12000);
}

document.addEventListener("DOMContentLoaded", function pageInit(event){

    let lab = new Labyrinth(20,20);
    world.walls = lab.getWalls();
    world.actionPanels = lab.getActionPanels();
    world.actionPanels.forEach(a => a.doAction = doAction);
    
    /** @type {HTMLCanvasElement} */
    canvas = document.getElementById("playfield");
    canvas.addEventListener("mouseup", onPlayfieldMouseUp);

    spnScore = document.getElementById("score");
    
    btnGhost = document.getElementById("btnGhost");
    btnGhost.addEventListener("click", onclickGhost);
    setTimeout(() => enableGhost(true), 10000);

    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    let [relX, relY] = calculateRanges(canvas.width, canvas.height);
    let context = canvas.getContext("2d");
    
    requestAnimationFrame(
        () => renderWorld(context, canvas.width, canvas.height, world.baseRange * relX, world.baseRange * relY, world.ego.x, world.ego.y)
    );
});