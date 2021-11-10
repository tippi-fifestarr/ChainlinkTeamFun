pragma solidity >=0.6.0 <0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/docs-v3.x/contracts/token/ERC721/ERC721.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./RandomTeamVRF.sol";

//turn a bytes32 into string, which will be like the prize
//Keeper will assign randomGroupNumbers
//win a prize everyday and require an NFT
//user can type on the NFT and then upload it as a ipfs file and push it into the mint card function
//make users put in eth and use that to fund the prize for the winners
//make a balance mapping

contract ChainlinkNFTCard is ERC721, RandomTeamVRF {

event NFTHolder(address indexed owner, string tokenURI, uint tokenId); 

uint256 public lastUpkeep;

address[] public NFTHolderAddresses;




address public owner;



uint public tokenCounter = 0;



mapping(address => bool) hasNFT; 


 constructor() public ERC721("ChainCard","CNC")  {
     
}



function mintCard(string memory tokenURI) public returns(uint) {
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
  

 function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData) {
 
        bool hasLink = LINK.balanceOf(address(this)) >= fee;
        bool enoughPlayers = NFTHolderAddresses.length > 1; 
        bool isTime = (block.timestamp - lastUpkeep) > 5 minutes; //This will be 24 hours in the final contract
        upkeepNeeded = hasLink && isTime && enoughPlayers;
}
    
    function performUpkeep(bytes calldata /*performData*/, uint numOfGroups) external {
        require(LINK.balanceOf(address(this)) >= fee, "not enough LINK");
        getRandomNumber();
        if(randomNumber != 0) {
             assignGroupNumbers(NFTHolderAddresses, numOfGroups);
        }
        
   }
   
   function numberofAddresses() public view returns(uint) {
       return NFTHolderAddresses.length;
   }
   
}

