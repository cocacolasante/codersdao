// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./CodersCrypto.sol";
import "./CodersNFT.sol";

contract StakingContract{
    ERC721[] public stakingNFTs;
    ERC20 public rewardsToken;
    address payable public admin;


    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call this feature");
        _;
    }


    constructor(){
        admin = payable(msg.sender);
    }

    // add a new nft contract for staking
    function addNftContract(ERC721 newNFT) public onlyAdmin {
        stakingNFTs.push(newNFT);
    }

    function setRewardsToken(ERC20 newRewardsToken) public onlyAdmin {
        rewardsToken = newRewardsToken;
    }




}