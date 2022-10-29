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
    //mapping of address to bool showing they have staked or not
    mapping(address=> bool) public hasStake;

    struct StakeInfo{
        uint256 startTime;
        uint256 endTime;        
        uint256 tokenId; 
        uint256 amountEarned; 
    }

    event Staked(address indexed staker, uint indexed tokenId);

    event Claimed(address indexed claimer, uint amountClaimed);


    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call this feature");
        _;
    }

    modifier hasStaked{
        require(hasStake[msg.sender] == true, "No NFTs Staked");
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
        
        hasStake[msg.sender] = true;

        stakingNFT.transferFrom(msg.sender, address(this), tokenId);

        emit Staked(msg.sender, tokenId);
    }

    
    // calculate rewards
    function calculateRewards() public view {
        require(hasStake[msg.sender] == true, "do not have any nfts staked");
        StakeInfo memory currentStake = usersStakes[msg.sender];
        

        uint timeStaked = (currentStake.endTime - currentStake.startTime);
        uint rewardsEarned = timeStaked * (rewardRate / 100);

        currentStake.amountEarned = rewardsEarned; 
    }

    function claimRewards() external hasStaked {
        StakeInfo memory currentStake = usersStakes[msg.sender];
        require(currentStake.endTime < block.timestamp, "stake is not over yet");

        calculateRewards();

        rewardsToken.transfer(msg.sender, currentStake.amountEarned);

        emit Claimed(msg.sender, currentStake.amountEarned);

    }


}