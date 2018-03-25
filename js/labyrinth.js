///<reference path="wall.js" />

"use strict";


class Labyrinth
{
    /**
     * Generates a new random labyrinth.
     * @param {number} tilesX Number of Tiles in x direction
     * @param {number} tilesY Number of Tiles in y direction
     */
    constructor(tilesX, tilesY)
    {
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
                if(i==0 || i==tiles[j].length-1 || j==0 || j==tiles.length-1){
                    tiles[j][i] = false;
                    continue;
                }
                tiles[j][i] = (Math.random() < 0.5);
            }
        }

        this.tiles = tiles;
    }


    getWalls()
    {
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