// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./JobContract.sol";


import "hardhat/console.sol";

contract CodersDAO is ReentrancyGuard, AccessControl{
    address public admin;
    
    address[] public stakeHolders;
    mapping(address=>bool) public isStakeholder;
    address[] public contributors;
    mapping(address => bool) public isContributor;


    uint public voteTimeMinimum = 1 weeks;
    uint public proposalNumber;

    // Job Smart Contract mapping

    mapping(uint => JobContract) public jobsMap;

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

    modifier isActiveStakeholder{
        require(isStakeholder[msg.sender] == true, "Not active stakeholder");
        _;
    }

    modifier isActiveContributor{
        require(isContributor[msg.sender] == true, "Not active contributor");
        _;
    }


    constructor(){
        admin = msg.sender;
    }
    receive() external payable{}

    // set up and remove role functions

    function setupStakeholder(address account) public onlyAdmin{     
        stakeHolders.push(account);
        isStakeholder[account] = true;

    }
    function removeStakeholder(address account) public onlyAdmin{    
        for(uint i; i < stakeHolders.length -1; i ++){
            if(stakeHolders[i] == account){
                stakeHolders[i] = stakeHolders[i+1];

                delete stakeHolders[i];
                isStakeholder[account] = false;

            }
        } 

    }

    function setupContributor(address account) public onlyAdmin{   
        contributors.push(account);
        isContributor[account] = true;

    }

    function removeContributor(address account) public onlyAdmin{    
        for(uint i; i < contributors.length -1; i ++){
            if(contributors[i] == account){
                contributors[i] = contributors[i+1];
                
                delete contributors[i];
                isContributor[account] = false;

            }
        } 

    }


    function getCurrentMembers() public onlyAdmin{

    }
    




    // proposal functions

    function createProposal(string memory propDescription) public isActiveStakeholder {
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


    function voteForProposal(uint propNum) public isActiveStakeholder {
        require(hasVotedForProp[msg.sender][propNum] == false, "Already voted");

        Proposal storage currentProp = allProposals[propNum];

        currentProp.votesFor += 1;
        hasVotedForProp[msg.sender][propNum] = true;


    }

    function voteAgainstProposal(uint propNum) public isActiveStakeholder {
        require(hasVotedForProp[msg.sender][propNum] == false, "Already voted");
        Proposal storage currentProp = allProposals[propNum];

        currentProp.votesAgainst += 1;

        hasVotedForProp[msg.sender][propNum] = true;


    }

    function calculateVotes(uint propNum) public onlyAdmin{
        Proposal storage currentProp = allProposals[propNum];
        // require(block.timestamp > currentProp.endTime, "voting period not over yet");
        uint forVotes = currentProp.votesFor;
        uint againstVotes = currentProp.votesAgainst;

        if(forVotes > againstVotes){
            currentProp.passed = true;
        } else{
            currentProp.passed = false;
        }
    
    }

    function createJob(uint propNum, uint estPaymentAmount, uint timeframe) public {
        Proposal storage currentProp = allProposals[propNum];
        require(msg.sender == currentProp.proposer || msg.sender == admin, "Not proposer or admin");
        require(currentProp.passed == true, "Proposal did not pass" );

        // logic to create job smart contract
        JobContract newJob = new JobContract(
            propNum,
            currentProp.proposer,
            estPaymentAmount,
            timeframe,
            address(this)
        );

        jobsMap[propNum] = newJob;


    }




    // send payout function

    function sendDaoPayout() public onlyAdmin{
        require(address(this).balance > 0, "No funds to transfer");
        require(stakeHolders.length > 0 && contributors.length > 0 ,"not enough stakeholders/contributors");
        uint stakeHolderAmount = (address(this).balance / 2 ) / stakeHolders.length;
        uint contributorAmount = (address(this).balance /2) / contributors.length;
        
        for(uint i; i < stakeHolders.length; i++){
            payable(stakeHolders[i]).transfer(stakeHolderAmount);
        }
        for(uint i; i < contributors.length; i++){
            payable(contributors[i]).transfer(contributorAmount);
        }

    }


    // helper functions

    function setNewAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }
}
