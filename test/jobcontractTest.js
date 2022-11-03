const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Job Smart Contract", async () =>{
    let JobContract, deployer, proposerUser, leadDevUser, dev1, dev2
    beforeEach(async () => {
        const accounts = await ethers.getSigners();

        deployer = accounts[0]
        proposerUser = accounts[1]
        leadDevUser = accounts[2]
        dev1 = accounts[3]
        dev2 = accounts[4]


        const jobContractFactory = await ethers.getContractFactory("JobContract")
        JobContract = await jobContractFactory.deploy(1, proposerUser.address, 10000, 86400 )
        await JobContract.deployed()

        
    })
    it("checks the accounts, payout, job number and completion date", async () =>{
        expect(await JobContract.proposer()).to.equal(proposerUser.address)
        expect(await JobContract.leadDev()).to.equal(proposerUser.address)
        expect(await JobContract.jobNumber()).to.equal(1)
        expect(await JobContract.payout()).to.equal(10000)
        expect(await JobContract.jobOpen()).to.equal(true);
    })
    it("checks the change lead function", async () =>{
        await JobContract.connect(proposerUser).changeLeadDev(leadDevUser.address)
        expect(await JobContract.leadDev()).to.equal(leadDevUser.address)
    })
    it("checks the add dev function", async () =>{
        await JobContract.connect(proposerUser).addDev(dev1.address)
        await JobContract.connect(proposerUser).addDev(dev2.address)
        expect(await JobContract.devs(0)).to.equal(dev1.address)
        expect(await JobContract.devs(1)).to.equal(dev2.address)
    })
    describe("Lead dev functions", async () =>{
        beforeEach(async () =>{
            await JobContract.connect(proposerUser).changeLeadDev(leadDevUser.address)
        })
        it("checks the assign task function", async () =>{
            await JobContract.connect(leadDevUser).assignTask(dev1.address, "create smart contract")
            const job1 = await JobContract.devsTasks(dev1.address, 1)
            expect(job1.description).to.equal("create smart contract")
            const allTask1 = await JobContract.allTasks(1)
            expect(allTask1.description).to.equal("create smart contract")
            
        })
    })
    
})