// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract CodersDAO is ReentrancyGuard, AccessControl{
    address public admin;
    
    bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR");
    bytes32 public constant STAKEHOLDER_ROLE = keccak256("STAKEHOLDER");

    address[] public currentContributors;

    uint public voteTimeMinimum = 1 weeks;
    uint public proposalNumber;

    mapping(address => mapping(uint => bool)) public hasVotedForProp;

    // mapping of uint to prop
    mapping(uint => Proposal) public allProposals;

    struct Proposal{
        address proposer;
        uint propNumber;
        uint startTime;
        uint endTime;
        uint votesFor;
        uint votesAgainst;
        string description;
        bool passed;
    }

    event ProposalCreated(address indexed proposer, uint indexed propNumber, uint startTime);

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier hasVoted(uint propNum){
        (hasVotedForProp[msg.sender][propNum] == false, "Already Voted for Prop");
        _;
    }


    constructor(){
        admin = msg.sender;
    }

    // set up and remove role functions

    function setupStakeholder(bytes32 role, address account) public {
        if(!hasRole(STAKEHOLDER_ROLE, account)){
            
        }
    }
    




    // proposal functions

    function createProposal(string memory propDescription) public {
        // create a require statement for "has role"
        proposalNumber++;

        Proposal memory newProp = Proposal(
            msg.sender,
            proposalNumber,
            block.timestamp,
            block.timestamp + voteTimeMinimum,
            0,
            0,
            propDescription,
            false
        );

        allProposals[proposalNumber] = newProp;

        emit ProposalCreated(msg.sender, proposalNumber, block.timestamp);
    }


    function voteForProposal(uint propNum) public {
        require(hasVotedForProp[msg.sender][propNum] == false, "Already voted");

        Proposal storage currentProp = allProposals[propNum];

        currentProp.votesFor += 1;
        hasVotedForProp[msg.sender][propNum] = true;


    }

    function voteAgainstProposal(uint propNum) public {
        require(hasVotedForProp[msg.sender][propNum] == false, "Already voted");
        Proposal storage currentProp = allProposals[propNum];

        currentProp.votesAgainst += 1;

        hasVotedForProp[msg.sender][propNum] = true;


    }





    // helper functions

    function setNewAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }
}
