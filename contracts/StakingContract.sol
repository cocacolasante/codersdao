// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./CodersCrypto.sol";
import "./CodersNFT.sol";

contract StakingContract{
    ERC721 public stakingNFT;
    ERC20 public rewardsToken;
    address payable public admin;

    uint public rewardRate = 1;

    // uint256 public stakeDuration = 2592000; // 30 days (30 * 24 * 60 * 60)


    // mapping of rewards to tokens
    mapping(address=>uint) public usersRewards;

    // mapping of address to stake info
    mapping(address => StakeInfo) public usersStakes;

    struct StakeInfo{
        uint256 startTime;
        uint256 endTime;        
        uint256 tokenId; 
        uint256 amountClaimed; 
    }

    event Staked(address indexed staker, uint indexed tokenId);


    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call this feature");
        _;
    }


    constructor(){
        admin = payable(msg.sender);
    }

    // UPDATER FUNCTIONS
    // add a new nft contract for staking
    function addNftContract(ERC721 newNFT) public onlyAdmin {
        stakingNFT = newNFT;
    }

    function setRewardsToken(ERC20 newRewardsToken) public onlyAdmin {
        rewardsToken = newRewardsToken;
    }

    function updateRewardRate(uint newRate) public onlyAdmin {
        rewardRate = newRate;
    }

     // staking function - duration needs to convert from days to seconds
    function stakeNFT(uint tokenId, uint duration) external {
        require(stakingNFT.ownerOf(tokenId) == msg.sender, "not owner of token");
        // conversion from days to seconds
        uint convertedDuration = duration * 24 * 60 * 60;

        usersStakes[msg.sender] = StakeInfo(
            block.timestamp,
            (block.timestamp + convertedDuration),
            tokenId,
            0
            );
        

        stakingNFT.transferFrom(msg.sender, address(this), tokenId);

        emit Staked(msg.sender, tokenId);
    }

    


}