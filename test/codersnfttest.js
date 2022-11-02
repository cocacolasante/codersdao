const { wait } = require("@testing-library/user-event/dist/utils");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const {moveTime} = require("../testing-utils/move-time")
const { moveBlocks } = require("../testing-utils/move-block")

const toWeiStr = (num) => ethers.utils.parseEther(num.toString())
const toWeiInt = (num) => ethers.utils.parseEther(num) 
const fromWei = (num) => ethers.utils.formatEther(num)

const delay = ms => new Promise(res => setTimeout(res, ms));

// eslint-disable-next-line no-undef
const halfSupply = (BigInt(10000000000000000000000000) / BigInt(2))

describe("Coders DAO", () =>{
    let CodersNFTContract, deployer, user1, user2
    const whiteListPrice = toWeiStr(1)


    beforeEach(async () =>{
        const codersNftFactory = await ethers.getContractFactory("CodersNFT")
        CodersNFTContract = await codersNftFactory.deploy()
        await CodersNFTContract.deployed()
        

        // console.log(`Coders NFT Deployed to ${CodersNFTContract.address}`)

        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        user1 = accounts[1]
        user2 = accounts[2]
    })
    it("checks the contract name and symbol", async () =>{
        expect(await CodersNFTContract.name()).to.equal("Coders DAO NFT")
        expect(await CodersNFTContract.symbol()).to.equal("CDN")
    })
    it("checks the current token count", async () =>{
        expect(await CodersNFTContract._tokenIdCounter()).to.equal(0)
    })
    it("checks the admin", async () =>{
        expect(await CodersNFTContract.admin()).to.equal(deployer.address)
    })
    describe("whitelist functions", () =>{
        beforeEach(async () =>{
            await CodersNFTContract.connect(deployer).addToWhitelist(user1.address)
            await CodersNFTContract.connect(deployer).setWhitelistMintLimit(3)
            await CodersNFTContract.connect(deployer).setWhitelistPrice(whiteListPrice)
        })
        it("checks the address was added to whitelist", async () =>{
            expect(await CodersNFTContract.isOnWhitelist(user1.address)).to.equal(true)
        })
        it("checks the whitelist limit", async () =>{
            expect(await CodersNFTContract.whitelistMintLimit()).to.equal(3)
        })
        it("checks the add whitelist fail case", async () =>{
            await expect(CodersNFTContract.connect(user2).addToWhitelist(user2.address)).to.be.reverted
        })
        it("checks the whitelist minting price", async () =>{
            expect(await CodersNFTContract.whitelistMintPrice()).to.equal(toWeiStr(1))
            
        })
        describe("whitelist minting function", () =>{
            let initialBalance
            beforeEach(async () =>{
                initialBalance = await ethers.provider.getBalance(deployer.address)
                // initialBalance = fromWei(initialBalance)
                await CodersNFTContract.connect(user1).whitelistMint(user1.address, {value: whiteListPrice});
            })
            it("checks the token owner", async () =>{
                expect(await CodersNFTContract.balanceOf(user1.address)).to.equal(1)
            })
            it("checks the token count", async () =>{
                expect(await CodersNFTContract._tokenIdCounter()).to.equal(1)
            })
            it("checks the admin received the minting fee", async () =>{
                // eslint-disable-next-line no-undef
                initialBalance = BigInt(initialBalance)

                // eslint-disable-next-line no-undef
                let whitelistPriceInt  = BigInt(1000000000000000000)

                expect(await ethers.provider.getBalance(deployer.address)).to.equal(initialBalance + whitelistPriceInt)

            })
            it("checks the whitelist mint limit fail case", async () =>{
                await CodersNFTContract.connect(user1).whitelistMint(user1.address, {value: whiteListPrice});
                await CodersNFTContract.connect(user1).whitelistMint(user1.address, {value: whiteListPrice});
                await expect(CodersNFTContract.connect(user1).whitelistMint(user1.address, {value: whiteListPrice})).to.be.reverted;
            })
            it("checks the whitelist pause modifier", async ()=>{
                await CodersNFTContract.connect(deployer).turnWLMintOff()
                await expect(CodersNFTContract.connect(user1).whitelistMint(user1.address, {value: whiteListPrice})).to.be.reverted
            })
            it("checks the token uri", async () =>{
                expect(await CodersNFTContract.tokenURI(1)).to.equal("ipfs/1.json")
            })
            
        })

        
    })
    describe("minting functions and burn function", () =>{
        let initialBalance
        beforeEach(async () =>{
            await CodersNFTContract.connect(deployer).setMintLimit(10)
            await CodersNFTContract.connect(deployer).setMintPrice(whiteListPrice)
            await CodersNFTContract.connect(deployer).unpauseContract()
            initialBalance = await ethers.provider.getBalance(deployer.address)
            await CodersNFTContract.connect(user2).mint(user2.address, {value: whiteListPrice})
            await CodersNFTContract.connect(user2).mint(user2.address, {value: whiteListPrice})
            await CodersNFTContract.connect(user2).mint(user2.address, {value: whiteListPrice})
        })
        it("checks the mint price", async () =>{
            expect(await CodersNFTContract.mintPrice()).to.equal(whiteListPrice)
        })
        it("checks the mint limit", async () =>{
            expect(await CodersNFTContract.mintLimit()).to.equal(10)
        })
        it("checks the token count", async () =>{
            expect(await CodersNFTContract._tokenIdCounter()).to.equal(3)
        })
        it("checks the token uri", async () =>{
            expect(await CodersNFTContract.tokenURI(3)).to.equal("ipfs/3.json")
        })
        it("checks the admin received the minting fee", async () =>{
            // eslint-disable-next-line no-undef
            initialBalance = BigInt(initialBalance)

            // eslint-disable-next-line no-undef
            let whitelistPriceInt  = BigInt(1000000000000000000)

            expect(await ethers.provider.getBalance(deployer.address)).to.equal(initialBalance + (whitelistPriceInt+whitelistPriceInt+whitelistPriceInt))

        })
        it("checks the burn function", async () =>{
            await CodersNFTContract.connect(user2).burn(2)
            expect(await CodersNFTContract.balanceOf(user2.address)).to.equal(2)
        })

        describe("ERC20 Token", () =>{
            let CodersCrypto
            beforeEach(async ()=>{
                const CryptoContractFactory = await ethers.getContractFactory("CodersCrypto")
                CodersCrypto = await CryptoContractFactory.deploy()
                await CodersCrypto.deployed()

                // console.log(`Contract deployed to ${CodersCrypto.address}`)
            })
            it("checks the token name", async () =>{
                expect(await CodersCrypto.name()).to.equal("Coders Crypto")
            })
            it("checks the token symbol", async () =>{
                expect(await CodersCrypto.symbol()).to.equal("CC")
            })
            it("checks the admin and contract deployer", async () =>{
                expect(await CodersCrypto.admin()).to.equal(deployer.address)
                expect(await CodersCrypto.contractDeployer()).to.equal(deployer.address)
            })
            it("checks the change admin function", async () =>{
                await CodersCrypto.connect(deployer).changeAdmin(user1.address)
                expect(await CodersCrypto.admin()).to.equal(user1.address)
            })
            describe("Staking contract", async () =>{
                let StakingContract
                beforeEach(async ()=>{
                    const stakingContractFactory = await ethers.getContractFactory("StakingContract")
                    StakingContract = await stakingContractFactory.deploy()
                    await StakingContract.deployed()

                    // console.log(`Staking contract deployed to ${StakingContract.address}`)
                })
                it("checks the admin", async() =>{
                    expect(await StakingContract.admin()).to.equal(deployer.address)
                })
                it("checks the nft contract was updated", async () =>{
                    await StakingContract.connect(deployer).addNftContract(CodersNFTContract.address)
                    expect(await StakingContract.stakingNFT()).to.equal(CodersNFTContract.address)
                    
                })
                it("checks the rewards token", async () =>{
                    await StakingContract.connect(deployer).setRewardsToken(CodersCrypto.address)
                    expect(await StakingContract.rewardsToken()).to.equal(CodersCrypto.address)
                })
                it("checks the fail case addnft, addrewards", async () =>{
                    await expect(StakingContract.connect(user2).setRewardsToken(CodersCrypto.address)).to.be.reverted
                    await expect(StakingContract.connect(user2).addNftContract(CodersNFTContract.address)).to.be.reverted

                })
                describe("Staking and Reward functions", async () =>{
                    let stakeInfoStruct, stakingStruct2
                    beforeEach(async () =>{
                        await StakingContract.connect(deployer).addNftContract(CodersNFTContract.address)
                        await StakingContract.connect(deployer).setRewardsToken(CodersCrypto.address)
                        
                        await CodersNFTContract.connect(user2).approve(StakingContract.address, 3)
                        await CodersNFTContract.connect(user2).approve(StakingContract.address, 2)
                        await StakingContract.connect(user2).stakeNFT(3) 
                        await StakingContract.connect(user2).stakeNFT(2) 

                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)
                        stakingStruct2 = await StakingContract.usersStakeByTokens(user2.address, 2)

                        // mint half of the rewards token supply to the staking contract
                        await CodersCrypto.connect(deployer).mint(StakingContract.address, halfSupply)

                    })
                    it("checks the nft staking owner", async () =>{
                        expect(await CodersNFTContract.ownerOf(3)).to.equal(StakingContract.address)
                    })
                    it("checks the stake info", async () =>{
                        expect(stakeInfoStruct.tokenId).to.equal(3)
                    })
                    it("checks the reward rate and claim function", async () =>{
                        await moveBlocks(1)
                        await moveTime(86400)
                        await StakingContract.connect(user2).calculateRewards(3)
                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)

                        console.log("amount earned", stakeInfoStruct.amountEarned.toString())
                        
                        await StakingContract.connect(user2).claimRewards(3)

                        expect(await CodersCrypto.balanceOf(user2.address)).to.equal(864)
                        await StakingContract.connect(user2).claimRewards(2)
                        expect(await CodersCrypto.balanceOf(user2.address)).to.equal(1728)
                        
                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)
                        console.log(stakeInfoStruct.amountEarned)

                        expect(stakeInfoStruct.amountEarned).to.equal(0)
                                   
                    })
                    it("checks the withdraw function", async () =>{
                        await moveBlocks(1)
                        await moveTime(86400)
                        await StakingContract.connect(user2).calculateRewards(3)
                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)

                        console.log("amount earned", stakeInfoStruct.amountEarned.toString())
                        
                        await StakingContract.connect(user2).withdrawStake(3)
                        expect(await CodersNFTContract.ownerOf(3)).to.equal(user2.address)
                        expect(await CodersCrypto.balanceOf(user2.address)).to.equal(864)

                    })
                    it("checks the failcase", async () =>{
                        await moveBlocks(1)
                        await moveTime(86400)
                        await StakingContract.connect(user2).calculateRewards(3)
                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)

                        console.log("amount earned", stakeInfoStruct.amountEarned.toString())
                        
                        await StakingContract.connect(user2).withdrawStake(3)
                        await expect(StakingContract.connect(user2).withdrawStake(3)).to.be.reverted;
                        await expect(StakingContract.claimRewards(3)).to.be.reverted
                    })
                    it("checks the nft can be restaked", async () =>{
                        await moveBlocks(1)
                        await moveTime(86400)
                        await StakingContract.connect(user2).calculateRewards(3)
                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)

                        console.log("amount earned", stakeInfoStruct.amountEarned.toString())
                        
                        await StakingContract.connect(user2).withdrawStake(3)

                        await CodersNFTContract.connect(user2).approve(StakingContract.address, 3)
                        await StakingContract.connect(user2).stakeNFT(3) 
                        
                        stakeInfoStruct = await StakingContract.usersStakeByTokens(user2.address, 3)
                        expect(stakeInfoStruct.stakeComplete).to.equal(false)
                    })

                })
            })
        })
        describe("Coder DAO Contract", async () =>{
            let DAOContract
            beforeEach(async () =>{
                const daoContractFactory = await ethers.getContractFactory("CodersDAO")
                DAOContract = await daoContractFactory.deploy()
                await DAOContract.deployed()


            })
            it("checks the admin was set", async () =>{
                expect(await DAOContract.admin()).to.equal(deployer.address)
            })
            it("checks the admin can be changed", async () =>{
                await DAOContract.connect(deployer).setNewAdmin(user1.address)
                expect(await DAOContract.admin()).to.equal(user1.address)
            })
            it("checks the fail case", async () =>{
                await expect(DAOContract.connect(user2).setNewAdmin(user2.address)).to.be.reverted
            })
            // describe the dao proposal functions
            describe("Proposal functions", async () =>{

                let proposalStruct
                beforeEach(async () =>{
                    await DAOContract.connect(user1).createProposal("Build an NFT project")
                    await DAOContract.connect(user2).voteForProposal(1)
                    proposalStruct = await DAOContract.allProposals(1)

                })
                it("checks the proposal count", async () =>{
                    expect(await DAOContract.proposalNumber()).to.equal(1)
                })
                it("checks the proposal struct", async () =>{
                    expect(proposalStruct.proposer).to.equal(user1.address)
                    expect(proposalStruct.propNumber).to.equal(1)
                    expect(proposalStruct.description).to.equal("Build an NFT project")
                })
                it("checks the voting for function", async () =>{
                    
                    expect(proposalStruct.votesFor).to.equal(1)
                })
                it("checks other users can vote on it", async () =>{
                    await DAOContract.connect(deployer).voteForProposal(1)
                    proposalStruct = await DAOContract.allProposals(1)
                    expect(proposalStruct.votesFor).to.equal(2)
                })
                it("checks the voting fail case", async () =>{
                    await expect(DAOContract.connect(user2).voteForProposal(1)).to.be.reverted
                })
                it("checks the vote against function", async () =>{
                    await DAOContract.connect(deployer).voteAgainstProposal(1)
                    proposalStruct = await DAOContract.allProposals(1)
                    expect(proposalStruct.votesAgainst).to.equal(1)
                })
            })
        })
    })
})