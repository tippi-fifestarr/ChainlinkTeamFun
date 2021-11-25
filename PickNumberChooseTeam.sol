pragma solidity >=0.6.0 <0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/docs-v3.x/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";


//figure 

contract PickNumberChooseTeam is VRFConsumerBase, ERC721, KeeperCompatibleInterface  {


  event NFTHolder(address indexed owner, string tokenURI, uint tokenId); 


  mapping (address => uint) public randomNumByAddr;

  address[] public teamOne;
  address[] public teamTwo;
  address[] public NFTHolderAddresses;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomNumber;
    uint256 public blockNumberResult;
    uint256 public lastUpkeep;
    uint public tokenCounter = 0;
    



  mapping(address => bool) hasNFT; 

  enum state_machine {
        OPEN,
        CLOSED
    }

   state_machine public s_state_machine;


   
    
    
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) ERC721("ChainCard","CNC")  public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public  returns(bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
        return requestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomNumber = randomness;
        blockNumberResult = block.number;
    }


function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData) {
 
        bool hasLink = LINK.balanceOf(address(this)) >= fee;
        bool isTime = (block.timestamp - lastUpkeep) > 15 seconds; //This will be 24 hours in the final contract
        upkeepNeeded = hasLink && isTime;
}
    
    function performUpkeep(bytes calldata /*performData*/) external override {
        require(LINK.balanceOf(address(this)) >= fee, "not enough LINK");
        getRandomNumber();
        s_state_machine = state_machine.OPEN;
        uint time = block.timestamp;

}

    function addToTeam(string memory tokenURI) public {
     require(s_state_machine == state_machine.OPEN, "Mission aren't open yet");
      randomNumByAddr[msg.sender] = randomNumber % 10;
      if(randomNumByAddr[msg.sender] > 4) {
      teamOne.push(msg.sender);
      } else {
     teamTwo.push(msg.sender);  
    }
    mintCard(tokenURI);
}

 function mintCard(string memory tokenURI) internal returns(uint) {
 require(hasNFT[msg.sender] != true, "You can only have one NFT");
  uint newTokenId = tokenCounter;
  _safeMint(msg.sender, newTokenId);
  _setTokenURI(newTokenId, tokenURI);
  tokenCounter = tokenCounter + 1;
  hasNFT[msg.sender] = true;
  NFTHolderAddresses.push(msg.sender);
  emit NFTHolder(msg.sender, tokenURI, newTokenId);
  return newTokenId;
}

}


