// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract JobContract{
    uint public jobNumber;
    bool public jobCompleted = false;
    bool public jobOpen;

    address public proposer;
    uint public payout;
    uint public maxCompletionDate;
    uint public taskNumber;
    
    
    address public leadDev;
    address[] public devs;

    //mapping dev to task
    mapping(address=>mapping(uint => Task)) public devsTasks;

    mapping(uint => Task) public allTasks;


    struct Task{
        address dev;
        uint taskNum;
        string description;
        bool completed;
    }

    event TaskCreated(uint indexed taskNum, address indexed dev);


    modifier onlyLeadDev {
        require(msg.sender == leadDev, "not lead dev");
        _;
    }

    constructor(uint _jobNumber, address _proposer, uint _payout, uint _maxCompleteDate){
        jobNumber = _jobNumber;
        proposer = _proposer;
        payout = _payout;
        maxCompletionDate = block.timestamp + (_maxCompleteDate *24 *60 *60);
        leadDev = _proposer;
        jobOpen = true;
    }

    // setter functions

    function addDev(address newDev) public onlyLeadDev {
        devs.push(newDev);
    }

    function changeLeadDev(address newLead) public onlyLeadDev {
        leadDev = newLead;
    }

    // add task function

    function assignTask(address devToAssign, string memory taskDesc) public onlyLeadDev{
        taskNumber++;

        Task memory newTask = Task(
            devToAssign,
            taskNumber,
            taskDesc,
            false
        );

        allTasks[taskNumber] = newTask;

        devsTasks[devToAssign][taskNumber] = newTask;


    }
}
