const { expect } = require("chai");
const { ethers } = require("hardhat");

const toWeiStr = (num) => ethers.utils.parseEther(num.toString())
const toWeiInt = (num) => ethers.utils.parseEther(num) 
const fromWei = (num) => ethers.utils.formatEther(num)

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
        })


    })
})