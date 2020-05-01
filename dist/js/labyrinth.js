///<reference path="./wall.js" />
///<reference path="./action-panel.js" />

"use strict";

/** Percentage of tiles, that will have ActionPanels. */
const LABYRINTH_ACTION_PERCENTAGE = 0.07;

class Labyrinth
{
    /**
     * Generates a new random labyrinth.
     * @param {number} tilesX Number of Tiles in x direction
     * @param {number} tilesY Number of Tiles in y direction
     */
    constructor(tilesX, tilesY)
    {
        /**
         * A checkerd matrix of booleans.
         * The values tell if there is a gateway between two tiles or not.
         * null values represent the tiles.
         * @type {boolean[][]}
         */
        let tiles = [];
        for(let j=0;j<tilesY*2+1;j++){
            tiles.push(new Array(tilesX*2+1));
        }

        for(let j=0;j<tiles.length;j++){
            for(let i=0;i<tiles[j].length;i++){
                if(i%2 == j%2){
                    tiles[j][i] = null;
                    continue;
                }
                // make sure, there is no way out of the labyrinth:
                if(i==0 || i==tiles[j].length-1 || j==0 || j==tiles.length-1){
                    tiles[j][i] = false;
                    continue;
                }
                tiles[j][i] = (Math.random() < 0.5);
            }
        }

        this.tiles = tiles;


        // generate positions for the action panels:
        this.actionPositions = [];

        for(let i=0;i<tilesX*tilesY*LABYRINTH_ACTION_PERCENTAGE;i++)
        {
            // this may produce multiple action panel on one tile:
            this.actionPositions.push([
                Math.floor(Math.random()*tilesX)*2+1,
                Math.floor(Math.random()*tilesY)*2+1
            ]);
        }
    }

    /**
     * Generates AcptionPanel objects from the internal representation.
     * @returns {ActionPanel[]}
     */
    getActionPanels()
    {
        let top = this.tiles.length/2;
        if(((this.tiles.length-1)/2)%2==0) top++;
        let left = -this.tiles[0].length/2;

        let panels = [];
        this.actionPositions.forEach(ap => {
            panels.push(new ActionPanel([
                [left+ap[0]+0.2,    top-ap[1]-0.2],
                [left+ap[0]+0.2,    top-ap[1]-0.8],
                [left+ap[0]+0.8,    top-ap[1]-0.8],
                [left+ap[0]+0.8,    top-ap[1]-0.2]
            ]));
        });

        return panels;
    }

    /**
     * Generates wall objects from the internal representation of the labyrinth.
     * @returns {Wall[]}
     */
    getWalls()
    {
        /** @type {Wall[]} */
        let wallList = [];

        let top = this.tiles.length/2;
        if(((this.tiles.length-1)/2)%2==0) top++;
        let bottom = top-1;
        // thickness of the wall:
        let t = 0.25;

        for(let j=0;j<this.tiles.length;j++,top--,bottom--){
            let left = -this.tiles[0].length/2;
            let right = left+1;
            for(let i=0;i<this.tiles[j].length;i++,left++,right++){
                if(this.tiles[j][i] == null){
                    continue;
                }
                if(j%2==0){
                    // vertical path
                    if(this.tiles[j][i] === true){
                        wallList.push(new Wall([
                            [left, top],
                            [left, bottom],
                            [left-t, bottom],
                            [left-t, top]
                        ]));
                        wallList.push(new Wall([
                            [right, top],
                            [right, bottom],
                            [right+t, bottom],
                            [right+t, top]
                        ]));
                    }
                    else {
                        if(j!=0)
                        wallList.push(new Wall([
                            [left-t, top-t],
                            [left-t, top],
                            [right+t, top],
                            [right+t, top-t]
                        ]));
                        if(j!=this.tiles.length-1)
                        wallList.push(new Wall([
                            [left-t, bottom+t],
                            [left-t, bottom],
                            [right+t, bottom],
                            [right+t, bottom+t]
                        ]));
                    }
                }
                else{
                    // horizontal path
                    if(this.tiles[j][i] === true){
                        wallList.push(new Wall([
                            [left, top+t],
                            [left, top],
                            [right, top],
                            [right, top+t]
                        ]));
                        wallList.push(new Wall([
                            [left, bottom-t],
                            [left, bottom],
                            [right, bottom],
                            [right, bottom-t]
                        ]));
                    }
                    else {
                        if(i!=0)
                        wallList.push(new Wall([
                            [left, top+t],
                            [left, bottom-t],
                            [left+t, bottom-t],
                            [left+t, top+t]
                        ]));
                        if(i!=this.tiles[j].length-1)
                        wallList.push(new Wall([
                            [right, top+t],
                            [right, bottom-t],
                            [right-t, bottom-t],
                            [right-t, top+t]
                        ]));
                    }
                }
            }
        }

        return wallList;
    }
}