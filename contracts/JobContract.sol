// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract JobContract{
    uint public jobNumber;
    bool public jobCompleted;

    address payable public proposer;
    uint public payout;
    uint public maxCompletionDate;
    uint public taskNumber;

    bool public fundsDeposited;

    address payable public DAOAddress;
    
    
    address payable public leadDev;
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

    modifier onlyProposer{
        require(msg.sender == proposer, "Only Job Proposer can call this function");
        _;
    }

    modifier notCompleted{
        require(jobCompleted == false, "Job is already completed");
        _;
    }

    receive() external payable{}

    constructor(uint _jobNumber, address  _proposer, uint _payout, uint _maxCompleteDate, address _daoAddress){
        jobNumber = _jobNumber;
        proposer = payable(_proposer);
        payout = _payout;
        maxCompletionDate = block.timestamp + (_maxCompleteDate *24 *60 *60);
        leadDev = payable(_proposer);
        DAOAddress = payable(_daoAddress);
    }

    // setter functions

    function addDev(address newDev) public onlyLeadDev notCompleted {
        devs.push(newDev);
    }

    function changeLeadDev(address newLead) public onlyLeadDev notCompleted{
        leadDev = payable(newLead);
    }

    // add task function

    function assignTask(address devToAssign, string memory taskDesc) public onlyLeadDev notCompleted{
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

    function completeTask(uint taskNum) public onlyLeadDev notCompleted{
        Task storage currentTask = allTasks[taskNum];

        currentTask.completed = true;

    }

    function reassignTask(address devToAssign, uint taskNum) public onlyLeadDev notCompleted{
        Task storage currentTask = allTasks[taskNum];

        devsTasks[currentTask.dev][taskNum] = devsTasks[devToAssign][taskNum];
        
        

        currentTask.dev = devToAssign;

    }


    // proposers function

    function completeJob() public onlyProposer {
        jobCompleted = true;
        uint amountToSend = (address(this).balance / 2 )/ (devs.length + 2);
        uint daoTransferAmount = address(this).balance / 2;

        for(uint i; i < devs.length; i++){
            payable(devs[i]).transfer(amountToSend);
        }

        proposer.transfer(amountToSend);

        leadDev.transfer(amountToSend);


        DAOAddress.transfer(daoTransferAmount);

    }

    function reopenJob() public onlyProposer {
        jobCompleted = false;
    }

    // deposit downpayment and payment for  dev team and proposer/lead dev
    function depositPaymentFromJob() public payable {
        
        
        payable(address(this)).transfer(msg.value);
        fundsDeposited = true;

    }
    



    // getter functions
    function returnBalance() public view returns(uint){
        return address(this).balance;

    }

}
