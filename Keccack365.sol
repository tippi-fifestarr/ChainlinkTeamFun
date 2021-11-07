pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Chainlink Keepers
//VRF to choose random teammates
// Have some type of counter that will keep track(mapping maybe) of the amount of nfts the owner has
//VRF activates every 24 hours

//Moralis
//Chainlink Keepers
//

//build something to keep up with
contract Keccak365 is ERC721, Ownable {
    event NFTHolder(address indexed owner, uint32 tokenId);

    // public state variable, intialized before the constructor function
    // this allows the code to know how many
    uint32 public tokenCounter = 0;
    // This is so that the code can keep track of how many NFTs
    // the owner has and that it doesn't go above 1 NFT.
    mapping(address => bool) hasNFT;

    // struct for each new Hacker
    struct Hacker {
        // should these be uint256?
        uint32 ageInDays;
        uint32 tokenID;
        address wingbird1;
        address wingbird2;
        bytes32 userName;
    }

    // mapping for addresses to hackers
    mapping(address => Hacker) hackers;
    address[] public hackerAccounts;

    struct DailyMission {
        string text;
        bool completed;
    }

    //make a mapping to obtain the url of that nft file
    constructor(uint32 _age, string _username)
        public
        ERC721("Keccack365: Daily, On-Chain TeamBuilding", "DAILY")
    {
        // find and set Hacker0
        var hacker = hackers[msg.sender];

        hacker.ageInDays = _age;
        hacker.userName = keccack256(_username);

        hackerAccounts.push(msg.sender);
        _safeMint(msg.sender, tokenId);
        tokenCounter++;
        hasNFT[msg.sender] = true;
    }

    function mintHacker(uint32 _age, string username) public returns (uint32) {
        require((!hasNFT[msg.sender]), "You can only have one NFT");
        uint32 newTokenId = tokenCounter;
        _safeMint(msg.sender, newTokenId);

        var hacker = hackers[msg.sender];

        hacker.ageInDays = _age;
        hacker.userName = keccack256(_username);

        tokenCounter++;
        hasNFT[msg.sender] = true;
        emit NFTHolder(msg.sender, newTokenId);
        return newTokenId;
    }
}
