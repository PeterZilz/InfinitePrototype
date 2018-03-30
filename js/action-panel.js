/// <reference path="./wall.js" />

"use strict";

class ActionPanel extends Wall
{

    /**
     * Constructs a new piece of wall.
     * @param {number[][]} polygon series of coordinates
     */
    constructor(polygon)
    {
        super(polygon);
        this.isActive = true;
        this.color = "#EB23D088";
    }

    doAction(){}
}