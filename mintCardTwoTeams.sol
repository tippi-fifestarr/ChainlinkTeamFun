pragma solidity 0.8.9;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./TeamLinkCard.sol";

contract mintCardTwoTeams is TeamLinkCard, VRFConsumerBase{
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
    //TOKEN URI HARDCODED ADDRESSES HERE
    string public tokenURI1 = "https://ipfs.moralis.io:2053/ipfs/QmPinUZsC5WPUKrWi9NGRV56eL3g5hTiViuyX3DzarEVV6";
    string public tokenURI2 = "https://ipfs.moralis.io:2053/ipfs/QmfP6idoq5FQEKgisbbPZke5f9phfXBotBKZPUNrL4tSsr";




  mapping(address => bool) hasNFT; 


 constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) ERC721("TeamLinkCard","TLC")  public
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
    
    
       function addToTeam(string memory tokenURI) public {
      randomNumByAddr[msg.sender] = randomNumber % 10;
      if(randomNumByAddr[msg.sender] > 4) {
      teamOne.push(msg.sender);
      } else {
     teamTwo.push(msg.sender);  
     mintCard(tokenURI1);
    }
    mintCard(tokenURI2);
}

 function mintCard(string memory _tokenURI) internal virtual returns(uint256) {
        require(hasNFT[msg.sender] != true, "You can only register once (one NFT only!)");
        // call a function from the other contract:
        //call the safemint 
        
        safeMint(msg.sender, _tokenURI);
        // successful mint? yeah!
       hasNFT[msg.sender] = true;
        NFTHolderAddresses.push(msg.sender);
         
    }

}
