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
    IERC20 public rewardsToken;
    address payable public admin;

    uint public rewardRate = 100;

    // uint256 public stakeDuration = 2592000; // 30 days (30 * 24 * 60 * 60)


    // mapping of rewards to tokens
    mapping(address=>uint) public usersRewards;


    // address to token id to stake info
    mapping(address=>mapping(uint => StakeInfo)) public usersStakeByTokens;

    //mapping of address to bool showing they have staked or not
    mapping(address=>mapping(uint=>bool)) public hasStake;

    struct StakeInfo{
        uint256 startTime;
        uint256 tokenId; 
        uint256 amountEarned; 
        bool stakeComplete;
    }

    event Staked(address indexed staker, uint indexed tokenId);

    event Claimed(address indexed claimer, uint amountClaimed);


    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call this feature");
        _;
    }

    modifier hasStaked(uint tokenId){
        require(hasStake[msg.sender][tokenId] == true, "No NFTs Staked");
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
    function stakeNFT(uint tokenId) external {
        require(stakingNFT.ownerOf(tokenId) == msg.sender, "not owner of token");


        usersStakeByTokens[msg.sender][tokenId] = StakeInfo(
            block.timestamp,
            tokenId,
            0,
            false
            );
        
        hasStake[msg.sender][tokenId] = true;

        stakingNFT.transferFrom(msg.sender, address(this), tokenId);

        emit Staked(msg.sender, tokenId);
    }

    
    // calculate rewards
    function calculateRewards(uint tokenId) public returns(uint){
        require(hasStake[msg.sender][tokenId] == true, "do not have any nfts staked");
        StakeInfo storage currentStake = usersStakeByTokens[msg.sender][tokenId];
        

        uint timeStaked = (block.timestamp - currentStake.startTime);

        uint rewardsEarned = timeStaked * (rewardRate / 100);

        return (currentStake.amountEarned = (rewardsEarned / 100)); 
    }


    function claimRewards(uint tokenId) public hasStaked(tokenId) {
        
        calculateRewards(tokenId);
        StakeInfo storage currentStake = usersStakeByTokens[msg.sender][tokenId];


        rewardsToken.transfer(msg.sender, currentStake.amountEarned);

        currentStake.startTime = block.timestamp;
        currentStake.amountEarned = 0;

        emit Claimed(msg.sender, currentStake.amountEarned);

    }


    function withdrawStake(uint tokenId) external hasStaked(tokenId){
        claimRewards(tokenId);
        StakeInfo storage currentStake = usersStakeByTokens[msg.sender][tokenId];
        require(currentStake.stakeComplete == false, "not currently staking nft");

        stakingNFT.transferFrom(address(this), msg.sender, tokenId);

        currentStake.stakeComplete = true;
        currentStake.amountEarned = 0;

        hasStake[msg.sender][tokenId] = false;
        

    }
    


}
