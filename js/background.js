///<reference path="render-utils.js" />
"use strict";


class Background 
{

    constructor()
    {
        // this.color1 = "#003f72";
        this.color1 = [0,0x3f,0x72, 255];
        // this.color2 = "#0069BE";
        this.color2 = [0,0x69,0xbe, 255];
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
        if(this.bufferWidth==width && this.bufferHeight==height 
            && this.bufferOffsetX==offsetX && this.bufferOffsetY==offsetY
            && this.buffer!=null){
            this.renderBuffer(context);
            return;
        }

        this.bufferWidth = width;
        this.bufferHeight = height;
        this.bufferOffsetX = offsetX;
        this.bufferOffsetY = offsetY;

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
                    renderColor = this.color1;
                else 
                    renderColor = this.color2;

                for(let k=0;k<renderColor.length;k++)
                {
                    data[dataCounter] = renderColor[k];
                    dataCounter++;
                }
            }
        }

        this.buffer = new ImageData(data, width, height);

        this.renderBuffer(context);
    }

    /**
     * 
     * @param {CanvasRenderingContext2D} context 
     */
    renderBuffer(context)
    {
        context.putImageData(this.buffer, 0, 0);
    }

}