///<reference path="render-utils.js" />
"use strict";


class Background 
{

    constructor()
    {
        this.color1 = "#003f72";
        this.color2 = "#0069BE";
    }

    /**
     * Renders the background on the given context.
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
        let x,y;
        for(let i=0;i<width;i++)
        {
            for(let j=0;j<height;j++)
            {
                [x,y] = unclip(i,j,width,height,rangeX,rangeY, offsetX, offsetY);
                if( (((x%2)+2)%2 < 1) != (((y%2)+2)%2 < 1) )
                {
                    context.fillStyle = this.color1;
                }
                else 
                {
                    context.fillStyle = this.color2;
                }

                context.fillRect(i,j,1,1);
                context.fill();
            }
        }
    }

}