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
    address payable public feeAccount;

    uint public tokenLimit = 339;

    uint256 public mintPrice;
    uint public mintLimit;

    bool public isContractLive;

    string private baseURI = "ipfs/";

    // white list
    address[] public whitelistAddresses;
    uint256 public whitelistMintLimit;
    mapping(address=>bool) public isOnWhitelist;
    uint public whitelistMintPrice;
    bool public isWLMintOn = true;

    // modifiers
    modifier onlyAdmin {
        require(msg.sender == admin, "only admin can call function");
        _;
    }

    modifier onWhitelist{
        require(isOnWhitelist[msg.sender] == true, "not on whitelist");
        _;
    }
    modifier WLMintUnpaused{
        require(isWLMintOn == true, "whitelist minting is not live");
        _;
    }

    modifier liveContract{
        require(isContractLive == true, "contract is not live yet");
        _;
    }

    constructor() ERC721("Coders DAO NFT", "CDN"){
        admin = payable(msg.sender);
        feeAccount = payable(msg.sender);
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

    function turnWLMintOn() public onlyAdmin{
        isWLMintOn = true;
    }

    function turnWLMintOff() public onlyAdmin{
        isWLMintOn = false;
    }


    function setWhitelistPrice(uint256 newWhitelistPrice) public onlyAdmin{
        whitelistMintPrice = newWhitelistPrice;
    }

    function whitelistMint(address to) payable public onWhitelist WLMintUnpaused {
        require(msg.value >= whitelistMintPrice, "Please pay full minting fee");
        require(_tokenIdCounter.current() < whitelistMintLimit, "max whitelist nfts minted");

        // transfer mint price to admin
        admin.transfer(msg.value);


        //increment token id
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        string memory newTokenURI = string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json'));
        //mint token
        _safeMint(to, tokenId);

        // set token uri
        _setTokenURI(tokenId, newTokenURI);
    }
    


    // regular mint functions
    function mint(address to) payable public liveContract {
        require(msg.value >= mintPrice, "Please pay full minting fee");
        require(_tokenIdCounter.current() < tokenLimit, "max nfts minted");

        // transfer mint price to admin
        admin.transfer(msg.value);


        //increment token id
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        string memory newTokenURI = string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json'));
        //mint token
        _safeMint(to, tokenId);

        // set token uri
        _setTokenURI(tokenId, newTokenURI);
    }


    function setMintLimit(uint256 newMintLimit) public onlyAdmin {
        mintLimit = newMintLimit;
    }

    function unpauseContract() public onlyAdmin{
        isContractLive = true;
    }

    function pauseContract() public onlyAdmin{
        isContractLive = false;
    }


    function setMintPrice(uint256 newWhitelistPrice) public onlyAdmin{
        mintPrice = newWhitelistPrice;
    }


    // overrides required by solidity

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) liveContract {
        super._burn(tokenId);
    }

    // burn function
    function burn(uint256 tokenId) external {
        address owner = ERC721.ownerOf(tokenId);
        require(owner == msg.sender, "not owner of token");
        _burn(tokenId);
    }

    function calculateFee() public view returns(uint){}

     function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
