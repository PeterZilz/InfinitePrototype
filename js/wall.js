/// <reference path="./render-utils.js" />

"use strict";


class Wall 
{
    /**
     * Constructs a new piece of wall.
     * @param {number[][]} polygon series of coordinates
     */
    constructor(polygon)
    {
        this.polygon = polygon;
        this.color = "#101010"
    }

    /**
     * Renders the wall on the given context.
     * @param {CanvasRenderingContext2D} context pane to render to
     * @param {number} width width in pixels
     * @param {number} height height in pixels
     * @param {number} rangeX width in coordinates
     * @param {number} rangeY height in coordinates
     * @param {number} offsetX x-coordinate of the center of the image
     * @param {number} offsetY y-coordinate of the center of the image
     */
    render(context, width, height, rangeX, rangeY, offsetX, offsetY)
    {

        let clippedPolygon = this.polygon.map(p => clip(p[0],p[1], width, height, rangeX, rangeY, offsetX, offsetY));

        // TODO check, if this polygon will even be visible.

        context.beginPath();
        context.fillStyle = this.color;
        clippedPolygon.forEach(p => context.lineTo(p[0],p[1]));
        context.fill()
        context.closePath();
    }
}