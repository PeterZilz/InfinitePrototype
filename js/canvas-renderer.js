/// <reference path="./render-utils.js" />
/// <reference path="./background.js" />
/// <reference path="./wall.js" />
/// <reference path="./man.js" />

"use strict";



/**
 * Renders the background on the given context.
 * @param {Background} background the background object to render
 * @param {CanvasRenderingContext2D} context pane to render to
 * @param {number} width width in pixels
 * @param {number} height height in pixels
 * @param {number} rangeX width in coordinates
 * @param {number} rangeY height in coordinates
 * @param {number} offsetX x-coordinate of the center of the image
 * @param {number} offsetY y-coordinate of the center of the image
 */
function renderBackground(background, context, width, height, rangeX, rangeY, offsetX, offsetY)
{
    // try to render the background, if possible.
    // If the view moved, then the buffer cannot be used.
    if(background.bufferWidth==width && background.bufferHeight==height 
        && background.bufferOffsetX==offsetX && background.bufferOffsetY==offsetY
        && background.buffer!=null){
        context.putImageData(background.buffer, 0, 0);
        return;
    }

    background.bufferWidth = width;
    background.bufferHeight = height;
    background.bufferOffsetX = offsetX;
    background.bufferOffsetY = offsetY;

    // TODO rendering each pixel individually is very inefficient!

    let data = new Uint8ClampedArray(4*width*height);
    let dataCounter = 0;
    let x,y;
    let renderColor;
    for(let j=0;j<height;j++)
    {
        for(let i=0;i<width;i++)
        {
            [x,y] = unclip(i,j,width,height,rangeX,rangeY, offsetX, offsetY);
            if( (((x%2)+2)%2 < 1) != (((y%2)+2)%2 < 1) )
                renderColor = background.color1;
            else 
                renderColor = background.color2;

            for(let k=0;k<renderColor.length;k++)
            {
                data[dataCounter] = renderColor[k];
                dataCounter++;
            }
        }
    }

    background.buffer = new ImageData(data, width, height);

    context.putImageData(background.buffer, 0, 0);
}

/**
 * Renders the wall on the given context.
 * @param {Wall} wall the obstacle to render
 * @param {CanvasRenderingContext2D} context pane to render to
 * @param {number} width width in pixels
 * @param {number} height height in pixels
 * @param {number} rangeX width in coordinates
 * @param {number} rangeY height in coordinates
 * @param {number} offsetX x-coordinate of the center of the image
 * @param {number} offsetY y-coordinate of the center of the image
 */
function renderWall(wall, context, width, height, rangeX, rangeY, offsetX, offsetY)
{
    if(wall.isOutsideScreen(rangeX, rangeY, offsetX, offsetY))
        return;

    let clippedPolygon = wall.polygon.map(p => clip(p[0],p[1], width, height, rangeX, rangeY, offsetX, offsetY));

    context.beginPath();
    context.fillStyle = wall.color;
    clippedPolygon.forEach(p => context.lineTo(p[0],p[1]));
    context.fill()
    context.closePath();
}

/**
 * Renders the man on the given context.
 * @param {Man} man the entity to render.
 * @param {CanvasRenderingContext2D} context pane to render to
 * @param {number} width width in pixels
 * @param {number} height height in pixels
 * @param {number} rangeX width in coordinates
 * @param {number} rangeY height in coordinates
 * @param {number} offsetX x-coordinate of the center of the image
 * @param {number} offsetY y-coordinate of the center of the image
 */
function renderMan(man, context, width, height, rangeX, rangeY, offsetX, offsetY)
{
    let m = clip(man.x, man.y, width, height, rangeX, rangeY, offsetX, offsetY);

    // TODO make drawRadius dependent on the clip function.
    let drawRadius = 10;
    
    context.beginPath();
    context.fillStyle = man.color;
    context.arc(m[0],m[1], drawRadius, 0, 2*Math.PI);
    context.fill();
    context.closePath();
}