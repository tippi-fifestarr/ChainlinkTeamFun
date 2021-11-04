pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract Raffle is VRFConsumerBase, KeeperCompatibleInterface {
    uint256 public s_entranceFee = 10 gwei;
    
address public s_recentWinner;
address payable[] public s_players;
enum State {Open, Calculating}
State public s_state;
uint256 public s_lastUpkeep;

address _linkToken = 0xa36085F69e2889c224210F603D836748e7dC0088;
address _vrfCoordinator = 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9;
bytes32 _keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
uint256 _chainlinkFee = 0.1 * 10 ** 18;

constructor() VRFConsumerBase (_vrfCoordinator, _linkToken) {
    
}

function enterRaffle() public payable {
    require(msg.value == s_entranceFee, 'please send 10 gwei');
    require(s_state == State.Open, "raffle is closed!");
    s_players.push(payable(msg.sender));
}

function checkUpkeep(bytes calldata /*checkData*/) public view override returns (
    bool upkeepNeeded, 
    bytes memory performData) {
        bool hasLink = LINK.balanceOf(address(this)) >= _chainlinkFee;
        bool isOpen = s_state == State.Open;
        bool isTime = (block.timestamp - s_lastUpkeep) > 1 hours; //or 1 days
        bool enoughPlayers = s_players.length > 1; 
        upkeepNeeded = hasLink && isOpen    && isTime && enoughPlayers;
    }

function performUpkeep(bytes calldata /*performData*/) external override {
    s_state = State.Calculating;
    require(LINK.balanceOf(address(this)) >= _chainlinkFee, "not enough LINK");
    requestRandomness(_keyHash, _chainlinkFee);
}

function fulfillRandomness(bytes32, uint256 randomness) internal override {
    uint256 randomWinner = randomness % s_players.length;
    address payable winner = s_players[randomWinner];
    s_recentWinner = winner;
    (bool success,) = winner.call{value: address(this).balance}("");
    require(success, "transfer to winner failed ");
    delete s_players;
    s_state = State.Open;
}

function status() public view returns (uint256, uint256 ) {
return (
    address(this).balance, s_players.length);
}
}
