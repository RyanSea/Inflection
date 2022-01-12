// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Point is Ownable, ERC20 {

  constructor() 
    payable 
    ERC20("Inflection", "POINT") 
  {
  
  }


  function mint(address account, uint256 amount) 
    public 
    onlyOwner
  {

		_mint(account, amount);

	}


}