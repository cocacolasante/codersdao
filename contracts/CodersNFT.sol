// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract CodersNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;

    address payable public admin;

    uint256 public mintPrice;

    // white list
    address[] public whitelistAddresses;
    uint256 public whitelistMintLimit;
    mapping(address=>bool) public isOnWhitelist;
    uint public whitelistMintPrice;

    // modifiers
    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call function");
        _;
    }

    modifier onWhitelist{
        require(isOnWhitelist[msg.sender] == true, "not on whitelist");
        _;
    }

    constructor() ERC721("Coders DAO NFT", "CDN"){
        admin = payable(msg.sender);
    }

    // whitelist functions
    function addToWhitelist(address walletToAdd) public onlyAdmin {
        isOnWhitelist[walletToAdd] = true;
    }
    function removeFromWhitelist(address walletToRemove) public onlyAdmin {
        isOnWhitelist[walletToRemove] = false;
    }

    function setWhitelistMintLimit(uint256 newMintLimit) public onlyAdmin {
        whitelistMintLimit = newMintLimit;
    }


    function setWhitelistPrice(uint256 newWhitelistPrice) public onlyAdmin{
        whitelistMintPrice = newWhitelistPrice;
    }

    function whitelistMint(address to, string memory uri) payable public onWhitelist {
        require(msg.value >= whitelistMintPrice, "Please pay full minting fee");
        require(_tokenIdCounter.current() < whitelistMintLimit, "max whitelist nfts minted");

        // transfer mint price to admin
        admin.transfer(msg.value);

        //increment token id
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        //mint token
        _safeMint(to, tokenId);

        // set token uri
        _setTokenURI(tokenId, uri);
    }
    






    // overrides required by solidity

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

     function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
