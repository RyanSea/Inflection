// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract Point is ERC20 {

  address public owner;

  event OwnerChanged(address indexed from, address to);

  constructor() 
    payable 
    ERC20("Inflection", "POINT") 
  { 
    owner = msg.sender;
  }

  function passOwnership(address inflection) 
    public 
    returns(bool)
  {
    require(msg.sender == owner, 'Error, only owner can transfer minter role');
    owner = inflection;

    emit OwnerChanged(msg.sender, inflection);
    return true;
  }

  function whoIsOwner() 
    public 
    view 
    returns(address) 
  {
    return owner;
  }

  function mint(address account, uint256 amount) 
    public 
  {
    require(msg.sender == owner, 'Error, sender is not owner');
		_mint(account, amount);
	}


}