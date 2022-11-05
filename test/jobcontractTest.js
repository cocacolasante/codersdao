const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Job Smart Contract", async () =>{
    let JobContract, deployer, proposerUser, leadDevUser, dev1, dev2, daoContract, user1, user2, user3, user4
    beforeEach(async () => {
        const accounts = await ethers.getSigners();

        deployer = accounts[0]
        proposerUser = accounts[1]
        leadDevUser = accounts[2]
        dev1 = accounts[3]
        dev2 = accounts[4]
        user1 = accounts[5]
        user2 = accounts[6]
        user3 = accounts[7]
        user4 = accounts[8]
        

        const daoContractFactory = await ethers.getContractFactory("CodersDAO")
        daoContract = await daoContractFactory.deploy()
        await daoContract.deployed()

        const jobContractFactory = await ethers.getContractFactory("JobContract")
        JobContract = await jobContractFactory.deploy(1, proposerUser.address, 10000, 86400, daoContract.address )
        await JobContract.deployed()


        
    })
    it("checks the accounts, payout, job number and completion date", async () =>{
        expect(await JobContract.proposer()).to.equal(proposerUser.address)
        expect(await JobContract.leadDev()).to.equal(proposerUser.address)
        expect(await JobContract.jobNumber()).to.equal(1)
        expect(await JobContract.payout()).to.equal(10000)
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
        it("checks the task completion function", async () =>{
            await JobContract.connect(leadDevUser).assignTask(dev1.address, "create smart contract")
            await JobContract.connect(leadDevUser).completeTask(1)
            let job1task = await JobContract.allTasks(1);

            expect(job1task.completed).to.equal(true)
        })
        it("checks the reassign task function", async () =>{
            await JobContract.connect(leadDevUser).assignTask(dev1.address, "create smart contract")
            let job1task
            await JobContract.connect(leadDevUser).reassignTask(dev2.address, 1)
            job1task = await JobContract.allTasks(1);
            expect(job1task.dev).to.equal(dev2.address)

        })
        describe("Proposer functions", () => {
            beforeEach(async () =>{
                await JobContract.connect(leadDevUser).addDev(dev1.address)
                await JobContract.connect(leadDevUser).addDev(dev2.address)
            })
            it("checks the deposit dev portion of funds function", async () =>{
                await JobContract.connect(proposerUser).depositPaymentFromJob({value: 100})
                expect(await JobContract.returnBalance()).to.equal(100)
            })
            
            it("checks the job completed and money transferred to devs", async () =>{
                await JobContract.connect(proposerUser).depositPaymentFromJob({value: 200})
                let initialBalance = await ethers.provider.getBalance(dev1.address)
                // eslint-disable-next-line no-undef
                initialBalance = BigInt(initialBalance)

                await JobContract.connect(proposerUser).completeJob()

                expect(await JobContract.jobCompleted()).to.equal(true)

                let currentBalance = await ethers.provider.getBalance(dev1.address)
                // eslint-disable-next-line no-undef
                currentBalance = BigInt(currentBalance);

                // eslint-disable-next-line no-undef
                expect(currentBalance).to.equal(initialBalance + BigInt(25))
            
            })
            it("checks the money was sent to the proposer and lead dev", async () =>{
                await JobContract.connect(proposerUser).depositPaymentFromJob({value: 200})
                let initialBalance = await ethers.provider.getBalance(leadDevUser.address)
                // eslint-disable-next-line no-undef
                initialBalance = BigInt(initialBalance)

                await JobContract.connect(proposerUser).completeJob()


                let currentBalance = await ethers.provider.getBalance(leadDevUser.address)
                // eslint-disable-next-line no-undef
                currentBalance = BigInt(currentBalance);
                
                // eslint-disable-next-line no-undef
                expect(currentBalance).to.equal(initialBalance + BigInt(25))

            })
            it("checks the closed job fail case", async () =>{
                await JobContract.connect(proposerUser).completeJob()
                await expect(JobContract.connect(leadDevUser).assignTask(dev1.address, "new task")).to.be.reverted

            })
            it("checks the dao contract received funds", async () =>{
                await JobContract.connect(proposerUser).depositPaymentFromJob({value: 200})

                await JobContract.connect(proposerUser).completeJob()

                expect( await ethers.provider.getBalance(daoContract.address)).to.equal(100)

            })
            it("checks the dao payment is sent out equally", async () =>{
                // set up the stakeholders
                await daoContract.connect(deployer).setupStakeholder(user1.address)
                await daoContract.connect(deployer).setupStakeholder(user2.address)
                await daoContract.connect(deployer).setupStakeholder(deployer.address)
                // set up the contributor accounts
                await daoContract.connect(deployer).setupContributor(dev1.address)
                await daoContract.connect(deployer).setupContributor(dev2.address)

                let initialBalance = await ethers.provider.getBalance(user2.address)
                // eslint-disable-next-line no-undef
                initialBalance = BigInt(initialBalance)

                await JobContract.connect(proposerUser).depositPaymentFromJob({value: 200})

                await JobContract.connect(proposerUser).completeJob()

                await daoContract.connect(deployer).sendDaoPayout()

                // eslint-disable-next-line no-undef
                expect(await ethers.provider.getBalance(user2.address)).to.equal(initialBalance + BigInt(16))

                

            })
            it("checks the fail cases for dao payment function", async () =>{
                await expect(daoContract.connect(deployer).sendDaoPayout()).to.be.reverted;

                await JobContract.connect(proposerUser).depositPaymentFromJob({value: 200})

                await expect(daoContract.connect(deployer).sendDaoPayout()).to.be.reverted;
            })
        })

    })
    
})