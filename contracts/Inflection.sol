//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC4626} from  "@rari-capital/solmate/src/mixins/ERC4626.sol";
import {Point} from "./Point.sol";

/// TODO Implement Auth 
/// @notice Protocol for tokenizing online engagement
/// based on the stake of the person engaging.
/// @notice ERC4626 compliant vault.
/// @author Autocrat
contract Inflection is ERC4626 {

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    Point public immutable point;

    constructor (Point _point) 
        ERC4626 (
            _point, 
            "Powered POINT", 
            "POWER"
        ) {
            point = _point;
        }
    
    /*///////////////////////////////////////////////////////////////
                            PROFILES
    //////////////////////////////////////////////////////////////*/

    struct Profile {
        // User's eoa
        address wallet;
        // User's mana after last engagement
        uint mana; 
        // Timestamp of user's last engagement
        uint lastEngagement;
    }
    /// @notice Discord id => Profile
    mapping (uint => Profile) public user;

    /// @notice Server id => server owner id (discord)
    mapping (uint => uint) public owner;

    /*///////////////////////////////////////////////////////////////
                                LOGIN
    //////////////////////////////////////////////////////////////*/

    /// @notice User authenticated with Ethereum wallet
    event Authenticate(address indexed _address, uint indexed discord_id);

    /// @notice Owner id assigned to server id (discord)
    event OwnerAssigned(uint indexed server_id, uint indexed owner_id);

    /// @notice Assigns address to a user's Profile struct and maps struct to discord id
    function authenticate(uint discord_id, address _address) public {
        // Create Profile struct 
        Profile memory profile;
        profile.wallet = _address;
        profile.mana = 100;
        // Assign profile to discord id
        user[discord_id] = profile;

        emit Authenticate(_address, discord_id);
    }

    function isAuthenticated(uint discord_id) public view returns (bool authenticated) {
        authenticated = user[discord_id].wallet != address(0);
    }

    /// @notice Assigns owner to server which will allow owner limit tokenized engagement privileges (TODO)
    function setServerOwner(uint discord_id, uint server_id) public {
        owner[server_id] = discord_id;
        emit OwnerAssigned(server_id, discord_id);
    }

    /*///////////////////////////////////////////////////////////////
                                STAKING
    //////////////////////////////////////////////////////////////*/

    /// @notice Staking event
    event PowerUp(
        uint indexed discord_id, 
        address indexed _address,
        uint amount
    );

    /// @notice Unstaking event
    event PowerDown(
        uint indexed discord_id,
        address indexed _address,
        uint amount
    );

    /// @notice Stake
    function powerUp(uint discord_id, uint amount) public returns (bool powered){
        address _address = user[discord_id].wallet;
        require((powered = point.balanceOf(_address) >= amount), "INSUFFICIENT_BALANCE");

        // I added approveFrom to solmate's ERC20.sol
        point.approveFrom(_address, address(this), amount);
        deposit(amount, _address);
        emit PowerUp(discord_id, _address, amount);
    }

    /// @notice Unstake
    function powerDown(uint discord_id, uint amount) public returns (bool depowered) {
        address _address = user[discord_id].wallet;
        require((depowered = balanceOf[_address] >= amount), "INSUFFICIENT_BALANCE");

        withdraw(amount, _address, _address);
        emit PowerDown(discord_id, _address, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        CORE ENGAGEMENT PROTOCOL
    //////////////////////////////////////////////////////////////*/

    /// @notice Rewards pool that fills with inflation and gets distrubuted as yield 
    uint public rewardPool;

    /// @notice Core team income, to pay for dev work and gas — TBD, unused for now
    uint public core;

    /// @notice Last time inflation was calculated 
    uint public last = block.timestamp;

    /// @notice Compound frequency in seconds | 1800 == 30 mins
    uint public duration = 1800;

    /// @notice Rate of inflation (x 100000) | 7 == 0.00007 | 9.9% /month @ 30 min freq
    uint public rate = 7;

    /// @notice The multiple required to get rate to a full number
    uint public multiple = 100000;

    /// @notice Engagement-action between users
    event Engagement(
        uint indexed from_discord_id,
        uint indexed to_discord_id,
        uint indexed time,
        uint value
    );

    /// @notice Inflation event
    event Inflation(uint time, uint amount);

    /// @notice The total amount of Powered POINT
    function totalAssets() public view override returns (uint total){
        total = totalSupply;
    }

    /// @notice Inflate the rewardsPool based on the amount of Powered POINT / total supply of POWER
    function inflate() public {
        // Caulculate inflation intervals since last inflation event
        uint current = block.timestamp;
        uint intervals = (current - last) /  duration;
        
        // Use total to compound inflation
        uint total = totalSupply;
        uint i;
        for(i ; i < intervals; i++) {
            total *= rate / multiple;
        }

        // Mint new inflation and add it to rewards pool
        uint inflation = total - totalSupply;
        point.mint(address(this), inflation);
        rewardPool += inflation;
        
        // Update last & emit event
        last = current;
        emit Inflation(last, inflation);
    }

    /// @notice Mana dictates user engagement power. It can be 1-100 
    /// it decreases by 10 with use and increases by 1 every 36 seconds
    function calculateMana(uint discord_id) private {
        // Add 1 mana for every 36 seconds that past since last engagement
        user[discord_id].mana += (block.timestamp - user[discord_id].lastEngagement) / 36;

        // Cap mana at 100
        if (user[discord_id].mana > 100) user[discord_id].mana = 100;
    }

    /// @notice Core engagement function
    /// TODO Clean this up
    /// TODO Reward server from engagement 
    function engage(
        // All params are discord id's
        uint engager_id, 
        uint engagee_id
    ) public {
        // Inflate (mint POINT + add to reward pool) and calculate engager's mana 
        inflate();
        calculateMana(engager_id);

        // Calculate value of engagement
        // POWER and mana of engager repepresent share of the reward pool
        Profile storage engager = user[engager_id];
        uint power = balanceOf[engager.wallet];
        uint value = rewardPool / power / 10 / 100 * engager.mana;

        // Mint POWER and distribute to engagee (80%) + engager (20%)
        // The POINT minted upon inflate() is now withdrawable
        _mint(engager.wallet, value * 20 / 100);
        _mint(user[engagee_id].wallet, value * 80 / 100);

        // Remove engagement value from reward pool
        rewardPool -= value;

        // Update engager's profile
        engager.lastEngagement = block.timestamp;
        engager.mana -= 10; // 10 mana is removed with each engagement to mitigate spam
        user[engager_id] = engager;

        emit Engagement(engager_id, engagee_id, block.timestamp, value);
    }

    
}