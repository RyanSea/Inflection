// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Point.sol";


//TODO add PowerUp + PowerDown functionality — Make PowerDown POINTs a pre-req for sending

contract Inflection is Ownable{

  //assign Token contract to variable
  Point private token;

  //Mappings

  // Server ID to Server Owner ID
  mapping(uint => uint) public serverOwner;
  // mapping(address => uint) public depositStart;
  mapping(address => bool) public isPoweredUp;
  // Discord ID to Address
  mapping(uint => address) public inflectionAccount;
  // map Discord ID (user and server) to Balance
  mapping(uint => uint) public balance;
  // map Discord ID to previous mana
  mapping(uint => uint) public previousMana;
  // map Discord ID to time of last engagement-action
  mapping(uint => uint) public previousEngagement;


  //add events
  event PowerUp(address indexed user, uint amount);
  event Engagement(uint indexed id, uint value, uint time);
  //pass as constructor argument deployed Token contract



  //Assign Token Contract to Inflection Upon Construction
  constructor(Point _point) 
  {

    token = _point;

  }

  //Assign Server ID to Server Owner's ID
  function assignServerOwner(uint userID, uint serverID)
    public
    onlyOwner
  {

    serverOwner[serverID] = userID;

  }

  //Returns Owner ID of Server
  function checkServerOwner(uint serverID) 
    public
    view
    returns(uint)
  {

    return serverOwner[serverID];

  }


  //Maps Discord ID to Ethereum Address
  function authenticate(uint discordID, address _address) 
    public
    onlyOwner 
  {
      
    inflectionAccount[discordID] = _address;

  }


  //Checks if Discord ID has an Ethereum Address Mapped to It
  function isAuthenticated(uint discordID) 
    public 
    view 
    returns(bool) 
  {

    return inflectionAccount[discordID] != address(0x0);

  }

  function hasBalance(uint discordID)
    public
    view
    returns(bool)
  {

    return balance[discordID] > 0;

  }


  function withdraw(uint discordID, uint _amount) 
    public
    onlyOwner 
  {

    address _address = inflectionAccount[discordID];
    uint bal = balance[discordID];
    uint amount = _amount * 10 ** 18;

    if (_address == address(0x0)) {
      return;
    } else if (bal == 0) {
      return;
    } else if (bal < amount) {
      
      token.transfer(_address, bal);
      balance[discordID] = 0;

    } else if (bal > amount) {
      
      token.transfer(_address, amount);
      balance[discordID] -= amount;
      
    }
    
  }


  //Returns balance of Protocol's Current Wallet
  function getContractBalance() 
    view 
    public 
    returns(uint)
  {

    return msg.sender.balance;

  }


  //Returns Balance of User Within Protocol
  function checkBalance(uint userID) 
    public 
    view 
    returns(uint)
  {

    return(balance[userID]);

  }


  //Core Engagement Function 
  function engage(uint engagerID, uint posterID, uint serverID) 
    public
    onlyOwner
  {

    // Requires users balance to be more than 1
    uint userBalance = balance[engagerID];
    require(userBalance > 1, "User has no balance to engage with");

    // Adds 1 point of Mana every 36 seconds from Previous Engagement up to a Max of 100
    uint manaIncrease = (block.timestamp - previousEngagement[engagerID]) / 36;
    uint mana = previousMana[engagerID] + manaIncrease;
    if(mana > 100){
      mana = 100;
    }
    
    // Calulate Engagement Value & Mint it
    uint engagementModifer = 1000; // 1000 = 10% Yield on Engagement at max Mana && 9% at 90 Mana
    uint engagementValue = userBalance * mana / engagementModifer; 
    token.mint(address(this), engagementValue);

    // Split Engagement Value between engager, engagee, protocol, and server
    balance[posterID] += engagementValue * 70 / 100;
    balance[engagerID] += engagementValue * 20 / 100;
    balance[serverID] += engagementValue * 7 / 100;

    // Subtracts 10% Mana from engager, assigns to engager'spreviousMana + logs time to enager's previousEngagement
    if (mana > 10) {
      mana -= (mana / 10);
    } else {
      mana -= 1;
    }
    previousMana[engagerID] = mana;
    previousEngagement[engagerID] = block.timestamp;

    emit Engagement(engagerID, engagementValue, block.timestamp);

  }

  

  function sendPOINT(uint senderID, uint receiverID, uint amount) 
    public
    onlyOwner 
  {

    if(balance[senderID] < amount){
      balance[receiverID] += balance[senderID];
      balance[senderID] -= balance[senderID];
    } else {
      balance[senderID] -= amount;
      balance[receiverID] += amount;
    }

  }

  function addPOINT(uint userID, uint _amount) 
    public 
    onlyOwner
  {
    uint amount = _amount * 10 ** 18;
    token.mint(address(this), amount);
    balance[userID] += amount;
  }

}