// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract CodersDAO is ReentrancyGuard, AccessControl{
    
    bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR");
    bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");

    address[] public currentContributors;

    address public admin;

    uint public voteTimeMinimum = 1 weeks;

    uint public numberOfProps;

    constructor(){
        admin = msg.sender;
    }

    function setupRole(bytes32 role, bytes32 adminRole) public {
        
    }


}
