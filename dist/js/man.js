"use strict";

class Man
{
    /**
     * Creates new instance of a Man.
     * @param {number} x x-coordinate of position
     * @param {number} y y-coordinate of position
     * @param {string} color color of the man as CSS color string
     */
    constructor(x,y,color)
    {
        /** @type {number} */
        this.x = x!=null ? x : 0;
        /** @type {number} */
        this.y = y!=null ? y : 0;
        this.color = color != null ? color : "#00A83E";

        /** @type {number[]} */
        this.destination = null;
    }

    /**
     * Determines if this entity has reached its destination.
     * @returns {boolean} false - if another step has to be taken.
     */
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

    /**
     * Moves this entity one step towards the current destination.
     */
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