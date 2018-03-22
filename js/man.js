"use strict";

class Man
{
    constructor(x,y,color)
    {
        this.x = x!=null ? x : 0;
        this.y = y!=null ? y : 0;
        this.color = color != null ? color : "#00A83E";

        this.destination = null;
    }


    /**
     * Renders the man on the given context.
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
        let m = clip(this.x, this.y, width, height, rangeX, rangeY, offsetX, offsetY);

        // TODO make radius dependent on the clip function.
        
        context.beginPath();
        context.fillStyle = this.color;
        context.arc(m[0],m[1], 10, 0, 2*Math.PI);
        context.fill();
        context.closePath();
    }

    isAtDestination()
    {
        if(this.destination == null) 
            return true;

        let dx = this.destination[0] - this.x;
        let dy = this.destination[1] - this.y;

        if(dx*dx + dy*dy < 0.01){
            return true;
        }
        else {
            return false;
        }
    }

    stepTowardsDestination()
    {
        if(this.isAtDestination()) 
            return;

        let speed = 0.2;

        let dx = this.destination[0] - this.x;
        let dy = this.destination[1] - this.y;

        if(dx*dx + dy*dy < speed*speed)
        {
            this.x = this.destination[0];
            this.y = this.destination[1];
            this.destination = null;
        }
        else {
            let d = Math.sqrt(dx*dx + dy*dy);
            dx *= speed / d;
            dy *= speed / d;

            this.x += dx;
            this.y += dy;
        }
    }
}