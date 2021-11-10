// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomTeamVRF is VRFConsumerBase{
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomNumber;
    uint256 public blockNumberResult;
    mapping (address => uint) public groupNumByAddr;
    
    
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) public
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

    function assignGroupNumbers(address[] memory addressArr, uint numGroups) public {
        require(numGroups > 0 && addressArr.length > numGroups-1,"revert");
        uint minGroupNumber = addressArr.length/numGroups;
        uint remainder = addressArr.length % numGroups;
        uint counter = 1;
        uint currIndex = 0;
        uint[] memory numInGroupArr = new uint[](numGroups);
        uint target;
        bool notUpdate;
        while (currIndex < addressArr.length){
            notUpdate = true;
            while(notUpdate){
                target = (uint256(keccak256(abi.encode(randomNumber, counter))) % numGroups);
                if(target< remainder && numInGroupArr[target] < minGroupNumber + 1){
                    numInGroupArr[target]++;
                    groupNumByAddr[addressArr[currIndex]] = target;//(you can add 1 if you want group to start at 1)
                    currIndex++;
                    notUpdate = false;
                    counter++;
                }
                else if(target >= remainder && numInGroupArr[target] < minGroupNumber){
                    numInGroupArr[target]++;
                    groupNumByAddr[addressArr[currIndex]] = target;//(you can add 1 if you want group to start at 1)
                    currIndex++;
                    counter++;
                    notUpdate = false;
                }
                else{
                    counter++;
                }
                
            }
        }        
    } 
}
