"use strict";

function onCanvasResize(event)
{
    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.style.height = (canvas.clientWidth / 2)+"px";
}


document.addEventListener("DOMContentLoaded", function pageInit(event){

    window.addEventListener("resize", onCanvasResize);
    
    onCanvasResize(null);
    
    /** @type {HTMLCanvasElement} */
    var canvas = document.getElementById("playfield");
    canvas.width = canvas.clientWidth;
    canvas.style.height = (canvas.clientWidth / 2)+"px";
    canvas.height = canvas.clientWidth / 2;
    var context = canvas.getContext("2d");
    
    new Background().render(context, canvas.width, canvas.height, 10, 5, 0, 0);
});