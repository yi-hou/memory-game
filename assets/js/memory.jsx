import React from "react";
import ReactDOM from 'react-dom';
import { Alert, Button } from 'reactstrap';
import { range } from 'underscore';


export default function game_init(root, channel) {
  ReactDOM.render(<MemoryGame channel={channel}/>, root);
}


class MemoryGame extends React.Component {  
  constructor(props) {
    super(props);
    this.channel = props.channel;
    this.state = {
    clicks: 0,
    tiles: [],
    matchedTiles: 0,
    selectedTile1: null,
    selectedTile2: null,
    };
    //join the channel
    this.channel.join().receive("ok", this.gotView.bind(this))
    .receive("error", resp => { console.log("Unable to join", resp)});
  }
 //get the view of the current state
 gotView(view) {
  console.log("New view", view);
  this.setState(view.game);
 }
 //after clicking reset button, trigger new() in game.ex to reset the game
  sendReset() {
    console.log("reset works!");
    this.channel.push("new")
    .receive("ok", this.gotView.bind(this));
  }
  //after clicking on the tile, send the tile information to the server side
  sendClick(tile) {
    console.log("click works!");
    this.channel.push("clickedOnTile", { tile: tile })
    .receive("ok", this.gotView.bind(this))
    .receive("checkMatch", this.sendCheckMatch.bind(this));
    
    console.log(this.state.tiles);
 }
  //after clicking two tiles, compare the information of the two tiles in the server-side
  //to see if they are matched or not.
  sendCheckMatch(view) {
    this.gotView(view);
    setTimeout(()=>{this.channel.push("checkMatch").receive("ok", this.gotView.bind(this))}, 1000);
  }

  // render the state image
  render() {
  // if all tiles are matched, render the winner image
    if(this.state.matchedTiles == 8){
      return (
        <div index ="over">
          <Alert index="win" >
          <p class="text-success">
            You Win!
            It only takes you {this.state.clicks} clickes!
          </p>
          </Alert> 
          <div className="col-12 text-center">
             <Reset new={this.sendReset.bind(this)} />
          </div>
        </div>
      )
      
    }

    else{
    return (
      <div>
          <RenderTiles state={this.state} clickedOnTile={this.sendClick.bind(this)} />
        <div className="row">
          <div className="col-6 text-center">
            <TrackClicks state={this.state} />
          </div>
         
          <div className="col-6 text-center">
            <Reset new={this.sendReset.bind(this)} />
          </div> 
        </div>  
      </div>
     );
    } 
  }
}
//render 4*4 grid tiles 
function RenderTiles(params) {
      let state = params.state

      let tiles = _.map(state.tiles, (tile, index) => {
        let symbol = 'T';
        if(tile.tileStatus == 'selected'){
           symbol = tile.letter;
        }
        else if(tile.tileStatus == 'matched') {
           symbol = 'ok';
        }
        else {
           symbol = 'T';
        }
        return( 
          <div className="col-3 text-center" key={index}>
            <div className="tile" onClick={() => params.clickedOnTile(tile)}>
              {symbol}
            </div>
          </div>
          ) 
        });
        return(
        <div className="row"> 
        {tiles}
        </div>
        )
}
//shows the clicks number on the screen
function TrackClicks(params) {
  let state = params.state;

  return (
  <div>
  <p>clicks: {state.clicks}</p>
  </div>);
}

//Reset button
function Reset(params) {
  let state = params.state;

  return(
    <div>
    <Button onClick={params.new}>Restart</Button>
    </div>
    );
}

