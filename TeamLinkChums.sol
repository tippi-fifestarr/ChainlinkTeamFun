// SPDX-License-Identifier: MIT
// deploy to Kovan for Keepers
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// this contract is a "day creator and mission maker"
// ideally we are having the chainlink keepers be the only thing that can create new categories
// which could be renamed into "day", the maximum amount is set by the admin on deployment
// there is currently no Hackathon Activities Sidechain Hub access control.
// the intended users are: 1) sidechain hackathon administrators 2) hackathon participants
// we'd like to incentivize daily participation with NFT and ERC20 rewards
// since there are no access controls, it seems very easy to put the "hack" back in hackathon
contract VerifyRandomTeam is KeeperCompatibleInterface {

    //"https://docs.moralis.io/moralis-server/automatic-transaction-sync/smart-contract-events"
    event PostCreated (bytes32 indexed postId, address indexed postOwner, bytes32 indexed parentId, bytes32 contentId, bytes32 nameId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    // in this version, "categories" are the Username/channel for posting.
    event NameCreated (bytes32 indexed nameId, string name);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);
    // notify UI of User Honesty Status Update (admin only function)
    event Honesty (address indexed user, bool isHonest);
    event Admin2Changed (address indexed admin2);
    event Admin3Changed (address indexed admin3);
    event StateOpened (address indexed adminAddress);
    event KeeperDidThat (uint8 indexed dayNum);
    
    uint256 public tokenCounter = 0;
    // intialized to 0
    uint256 public dayNum;
    // uint256 public openedOn; // when the contract state is OPENED
    uint256 public lastUpkeep; // keeping track of time
    // uint256 internal fee;

    struct options {
        address admin1;
        address admin2;
        address admin3;
        // how many hours per "day"
        uint256 secondsPerDay;
        bool isReady;
    }

    // this is a post struct allows comments apparently
    struct post {
        address postOwner; // who posted
        bytes32 parentPost; // implement comments
        bytes32 contentId;  // the IPFS metadata
        bytes32 nameId; // the string hashed
        int40 votes; // an amount of votes
    }

    // dishonest by default 
    mapping (address => bool) honestUsers;
    // rereference 
    // each user has a total reputation for each name?
    mapping (address => mapping (bytes32 => uint80)) reputationRegistry; 
    mapping (bytes32 => string) nameRegistry; // name id and string
    mapping (bytes32 => string) contentRegistry; // cID and url at IPFS?
    mapping (bytes32 => post) postRegistry;  // post id to post struct
    mapping (address => mapping (bytes32 => bool)) voteRegistry; // user mapped to postId and voted or not

    // users are expected to post their planned amount of work time each day (as well as "clock out" and share their work)
    // this maps user address to a map of days and user inputted time
    mapping (address => mapping (uint8 => uint8)) plannedWorkByDay;
    // here we track the users "actual" (self-reported) work time (on clock out)
    mapping (address => mapping (uint8 => uint8)) actualWorkByDay;
    // tracks user by day and "what they did" (CID for IPFS)
    mapping (address => mapping (uint8 => string)) dailyReports;
    // random number stored for address

    enum state_machine {
        SETUP,
        OPEN,
        CALCULATING,
        DAILY,
        CLOSED
    }

    // keeps track of the different states of the machine
    state_machine public s_state_machine;
    
    // this is the struct holding the options for setup
    options public AdminOptions;

    // this contract will wait one "DAY" after opening
    // ask the admin how many hours per day?
    constructor () public {

        AdminOptions.admin1 = msg.sender;

        // fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        s_state_machine = state_machine.SETUP;

        // tell the Keepers when to start checking
        // tell the Keepers how long each "day" is
    }

    // require that one of the admins is calling this
    function setupContractOptions(uint256 _hoursPerDay) external {
        require(AdminOptions.admin1 == msg.sender 
        || AdminOptions.admin2 == msg.sender || 
        AdminOptions.admin3 == msg.sender, "only admins can setupContractOptions");
        require(_hoursPerDay < 365, "hours per day must be less than 365 for security reasons");
        require(s_state_machine == state_machine.SETUP, "options can only be set during SETUP");
        AdminOptions.secondsPerDay = _hoursPerDay * 3600;
        AdminOptions.isReady = true;

    }
    
    function setAdmin2(address _admin2) public {
        require(AdminOptions.admin1 == msg.sender || AdminOptions.admin3 == msg.sender);
        require(AdminOptions.admin2 == address(0));
        require(_admin2 != address(0));
        require(s_state_machine == state_machine.SETUP);
        AdminOptions.admin2 = _admin2;
        emit Admin2Changed (AdminOptions.admin2);
    }

    function setAdmin3(address _admin3) public {
        require(AdminOptions.admin1 == msg.sender || AdminOptions.admin2 == msg.sender);
        require(AdminOptions.admin3 == address(0));
        require(_admin3 != address(0));
        require(s_state_machine == state_machine.SETUP);
        AdminOptions.admin3 = _admin3;
        emit Admin3Changed (AdminOptions.admin3);
    }

    // this function should only be callable by admins and changes the state to OPEN
    function launchSHA365() external {
        require(s_state_machine == state_machine.SETUP, "Can only launch from setup mode");
        require(AdminOptions.admin1 == msg.sender || AdminOptions.admin2 == msg.sender || AdminOptions.admin3 == msg.sender, "You are not an admin");
        require(AdminOptions.admin1 != address(0) && AdminOptions.admin2 != address(0) && AdminOptions.admin3 != address(0), "Requires all admin roles set");
        require(AdminOptions.isReady == true, "not all options are set");
        s_state_machine = state_machine.OPEN;
        lastUpkeep = block.timestamp;
        emit StateOpened(msg.sender);
    }

        // functions as the registry
    // 1. user presses a button
    // 3. added to the registry
    function register(string memory name) public returns (bytes32) {
        require(s_state_machine == state_machine.OPEN, "can only register during OPEN state of contract. Is the contract calculating, not open yet, or already closed?");
        s_state_machine = state_machine.CALCULATING; // prevent two users from calling this function at the same time?
        addNameToRegister(name);
        s_state_machine = state_machine.OPEN;
    }

  
    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData) {
            bool isOpen = s_state_machine == state_machine.OPEN || s_state_machine == state_machine.DAILY; 
            // bool hasLink = LINK.balanceOf(address(this)) >= fee;
            bool isTime = (block.timestamp - lastUpkeep) > (AdminOptions.secondsPerDay); //this amount determined by admin in deploy
            upkeepNeeded = /* hasLink && */ isOpen && isTime;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        // require(LINK.balanceOf(address(this)) >= fee, "not enough LINK");
        s_state_machine == state_machine.CALCULATING;
        lastUpkeep = block.timestamp;
        dayNum = dayNum + 1;
        if (dayNum > 365) {
            s_state_machine == state_machine.CLOSED;
        } else {
            s_state_machine == state_machine.DAILY;
        }
        emit KeeperDidThat(dayNum); // emitting the event is how we track the days?

    }
    // called by the register function
    function addNameToRegister(string calldata _name) internal {
        bytes32 _nameId = keccak256(abi.encode(_name));
        // is this like the thing I "improved" Larry's code with? perhaps easier to read?
        nameRegistry[_nameId] = _name;
        // every time a new "day" is created, 
        emit NameCreated(_nameId, _name);
    }
    /// _parentId could be empty
    /// where w store the content
    /// the name id is the name where the post lives
    function createPost(bytes32 _parentId, string calldata _contentUri, bytes32 _nameId) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        // hashes the owner, parent id, and content id (v clever)
        bytes32 _postId = keccak256(abi.encodePacked(_owner,_parentId, _contentId));
        contentRegistry[_contentId] = _contentUri;
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].parentPost = _parentId;
        postRegistry[_postId].contentId = _contentId;
        postRegistry[_postId].nameId = _nameId;
        emit ContentAdded(_contentId, _contentUri); // these are how we fetch it in UI
        emit PostCreated (_postId, _owner,_parentId,_contentId,_nameId); // post struct
    }

    function voteUp(bytes32 _postId, uint8 _reputationAdded) external {
        address _voter = msg.sender;
        bytes32 _name = postRegistry[_postId].nameId;
        address _contributor = postRegistry[_postId].postOwner;
        require (postRegistry[_postId].postOwner != _voter, "you cannot vote your own posts");
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        require (validateReputationChange(_voter,_name,_reputationAdded)==true, "This address cannot add this amount of reputation points");
        postRegistry[_postId].votes += 1;
        reputationRegistry[_contributor][_name] += _reputationAdded;
        // this is irreversible, updating the registry for that voter(on this post) already voted
        // we could add a uint 
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_name], reputationRegistry[_voter][_name], postRegistry[_postId].votes, true, _reputationAdded);
    }

    function voteDown(bytes32 _postId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _name = postRegistry[_postId].nameId;
        address _contributor = postRegistry[_postId].postOwner;
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        require (validateReputationChange(_voter,_name,_reputationTaken)==true, "This address cannot take this amount of reputation points");
        postRegistry[_postId].votes >= 1 ? postRegistry[_postId].votes -= 1: postRegistry[_postId].votes = 0;
        reputationRegistry[_contributor][_name] >= _reputationTaken ? reputationRegistry[_contributor][_name] -= _reputationTaken: reputationRegistry[_contributor][_name] =0;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_name], reputationRegistry[_voter][_name], postRegistry[_postId].votes, false, _reputationTaken);
    }

    // function with logarithmic characteristic (in else)
    // if the reputation is lower than 2, then they can only add one
    // later on can implement this logarithmic weighting or delete and replace with modifier?
    function validateReputationChange(address _sender, bytes32 _nameId, uint8 _reputationAdded) internal view returns (bool _result){
        uint80 _reputation = reputationRegistry[_sender][_nameId];
        if (_reputation < 2 ) {
            _reputationAdded == 1 ? _result = true: _result = false;
        }
        // this is the logarithmic, if your rep is 4 you can add 2, 8 can add 4
        else {
            2**_reputationAdded <= _reputation ? _result = true: _result = false;
        }
    }

    
    function getContent(bytes32 _contentId) public view returns (string memory) {
        return contentRegistry[_contentId];
    }
    
    function getName(bytes32 _nameId) public view returns(string memory) {   
        return nameRegistry[_nameId];
    }

    function getReputation(address _address, bytes32 _nameID) public view returns(uint80) {   
        return reputationRegistry[_address][_nameID];
    }

    function getPost(bytes32 _postId) public view returns(address, bytes32, bytes32, int72, bytes32) {   
        return (
            postRegistry[_postId].postOwner,
            postRegistry[_postId].parentPost,
            postRegistry[_postId].contentId,
            postRegistry[_postId].votes,
            postRegistry[_postId].nameId);
    }

    // the admin (deployer, for now) can assign an honesty value to the users.
    function usersHonest(address _userAddress, bool _adminOpinion) public {
        // access control here (otherwise this is an attack vector;)
        require(AdminOptions.admin1 == msg.sender || AdminOptions.admin2 == msg.sender || AdminOptions.admin3 == msg.sender, "You are not an admin");
        honestUsers[_userAddress] = _adminOpinion;
        emit Honesty(_userAddress, _adminOpinion);
        }

    // user submits their time
    // function timeBlox(uint8 _timeblock) public {


    // }

}