"use strict";

/**
 * A container object for information on how to render the floor.
 */
class Background 
{
    constructor()
    {
        // this.color1 = "#003f72";
        this.color1 = [0,0x3f,0x72, 255];
        // this.color2 = "#0069BE";
        this.color2 = [0,0x69,0xbe, 255];

        /** @type {ImageData} */
        this.buffer = null;
        /** @type {number} */
        this.bufferWidth = null;
        /** @type {number} */
        this.bufferHeight = null;
        /** @type {number} */
        this.bufferOffsetX = null;
        /** @type {number} */
        this.bufferOffsetY = null;
    }
}