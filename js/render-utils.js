"use strict";


/**
 * Transforms coordinates to pixel position. 
 * @param {number} x 
 * @param {number} y 
 * @param {number} width number or horizontal pixels
 * @param {number} height number of vertical pixels
 * @param {number} rangeX width in terms of coordinates not pixels
 * @param {number} rangeY height in terms of coordinates not pixels
 * @param {number} offsetX offset is the coordinate, which is in the middle of the screen
 * @param {number} offsetY offset is the coordinate, which is in the middle of the screen
 * @return {number[]}
 */
function clip(x,y,width, height, rangeX, rangeY, offsetX, offsetY)
{
    let px = width*((x-offsetX)+rangeX/2)/rangeX;
    let py = height*(-(y-offsetY)+rangeY/2)/rangeY;

    return [px,py];
}

/**
 * Transforms pixel position to coordinate. 
 * @param {number} px 
 * @param {number} py 
 * @param {number} width number or horizontal pixels
 * @param {number} height number of vertical pixels
 * @param {number} rangeX width in terms of coordinates not pixels
 * @param {number} rangeY height in terms of coordinates not pixels
 * @param {number} offsetX offset is the coordinate, which is in the middle of the screen
 * @param {number} offsetY offset is the coordinate, which is in the middle of the screen
 * @return {number[]}
 */
function unclip(px,py,width, height, rangeX, rangeY, offsetX, offsetY)
{
    let x = px*rangeX / width - rangeX/2 + offsetX;
    let y = (-py*rangeY / height + rangeY/2) + offsetY;

    return [x,y];
}