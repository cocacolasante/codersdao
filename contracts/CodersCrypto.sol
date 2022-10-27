// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract CodersCrypto is ERC20, ERC20Burnable, Ownable {
    uint public maxSupply = 10000000000000000000000000;
    uint public currentCount;
    address payable public immutable contractDeployer;
    address public admin;

    modifier onlyAdmin{
        require(msg.sender == admin, "only admin can call function");
        _;
    }


    constructor() ERC20("Coders Crypto", "CC") {
        contractDeployer = payable(msg.sender);
        admin = msg.sender;
    }

    function mint(address to, uint256 amount)  public onlyAdmin{
        uint afterPurchaseSupply = amount + currentCount;
        require(afterPurchaseSupply < maxSupply, "Not enough left to mint");
        _mint(to, amount);
        currentCount+=amount;
    }
    
    function burn(uint256 amount) public override {
        _burn(_msgSender(), amount);
        currentCount -= amount;
    }

    function changeAdmin(address newAdmin) public onlyAdmin{
        admin = newAdmin;
    }


    function returnCurrentSupply() external view returns(uint){
        return currentCount;
    }
}