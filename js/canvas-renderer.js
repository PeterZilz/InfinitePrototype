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

    let [cornerX, cornerY] = unclip(0, 0,width,height,rangeX,rangeY,offsetX,offsetY);
    // calculate the length of "1" in terms of pixels
    let [pixelLengthX, pixelLengthY] = clip(cornerX+1, cornerY-1, width,height,rangeX,rangeY,offsetX,offsetY);

    // calculate the field, that has to be filled with background tiles.
    let minX = Math.floor(cornerX);
    let maxY = Math.ceil(cornerY);
    let maxX = Math.ceil(cornerX + rangeX);
    let minY = Math.floor(cornerY - rangeY);

    // fill the background with one color,
    // so that from the checker pattern only the other color has to be renderd as tiles.
    context.beginPath();
    context.fillStyle = background.color2String;
    context.fillRect(0,0,width,height);
    context.fill();
    
    // render tiles of the other color
    context.fillStyle = background.color1String;
    for(let x = minX;x<maxX;x+=2)
    {
        for(let y = minY, j=0;y<=maxY;y++,j++){
            let [px, py] = clip(x+((minX+minY+j)%2),y,width,height,rangeX,rangeY,offsetX,offsetY);
            context.fillRect(px, py, pixelLengthX, pixelLengthY);
            context.fill();
        }
    }
    context.closePath();
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