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
        this.color = "#101010";

        this.calculateBounndingBox();
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

        if(this.isOutsideScreen(rangeX, rangeY, offsetX, offsetY))
            return;

        let clippedPolygon = this.polygon.map(p => clip(p[0],p[1], width, height, rangeX, rangeY, offsetX, offsetY));

        context.beginPath();
        context.fillStyle = this.color;
        clippedPolygon.forEach(p => context.lineTo(p[0],p[1]));
        context.fill()
        context.closePath();
    }

    /**
     * Calculates the bounding box of the polygon.
     */
    calculateBounndingBox()
    {
        let minX = this.polygon[0][0];
        let minY = this.polygon[0][1];
        let maxX = this.polygon[0][0];
        let maxY = this.polygon[0][1];

        this.polygon.forEach(p => {
            minX = Math.min(p[0], minX);
            minY = Math.min(p[1], minY);
            maxX = Math.max(p[0], maxX);
            maxY = Math.max(p[1], maxY);
        });

        this.boundingBox = {
            minX, minY,
            maxX, maxY
        };
    }

    /**
     * Checks via the bounding box if this element might be visible.
     * @param {number} rangeX width of the shown screen in coordinates (not pixels)
     * @param {number} rangeY height of the shown screen in coordinates (not pixels)
     * @param {number} offsetX coordinates of the center of the shown screen
     * @param {number} offsetY coordinates of the center of the shown screen
     * @returns {boolean} true: if the bounding box lies outside the shown scree, false otherwise
     */
    isOutsideScreen(rangeX, rangeY, offsetX, offsetY){
        let top = offsetY + rangeY/2;
        let bottom = offsetY - rangeY/2;
        let left = offsetX - rangeX/2;
        let right = offsetX + rangeX/2;

        return (
            this.boundingBox.minX > right ||
            this.boundingBox.maxX < left ||
            this.boundingBox.minY > top ||
            this.boundingBox.maxY < bottom
        );
    }

    /**
     * Checks if coordinate is inside the bounding box
     * @param {number} x 
     * @param {number} y 
     */
    isInsideBoundingBox(x, y)
    {
        return (
            this.boundingBox.minX <= x &&
            this.boundingBox.maxX >= x &&
            this.boundingBox.minY <= y &&
            this.boundingBox.maxY >= y
        );
    }
}