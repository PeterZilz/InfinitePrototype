"use strict";

/**
 * Represents an area, that cannot be walked on.
 * It does not necessarily have to be a rectangle.
 * But currently only that works for actual obstacle checking.
 */
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
     * Calculates the bounding box of the polygon.
     * Has to be called every time the position of shape of this object changes.
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
     * @returns {boolean}
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