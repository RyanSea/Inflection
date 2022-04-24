//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC20} from  "@rari-capital/solmate/src/tokens/ERC20.sol";

contract Point is ERC20 {

    constructor() ERC20("Inflection Point Token", "POINT", 18) {}

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }

    function approveFrom(address owner, address spender, uint amount) public {
        _approve(owner, spender, amount);
    }
    
}