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

    string private baseURI = "https://ipfs.io/ipfs/QmVXjMCb3QLssDJ6oq6n77vR7zPPTmNaj19n21uq2N6JSi/";

    // white list
    address[] public whitelistAddresses;
    uint256 public whitelistMintLimit;
    mapping(address=>bool) public isOnWhitelist;
    uint public whitelistMintPrice;
    bool public isWLMintOn = true;

    
    uint public royaltyFee;

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
        isContractLive = true;
        mintPrice = 1000000000000000000;
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


     function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }


    function _payRoyalty(uint _royalty) internal {
        payable(admin).transfer(_royalty);
        
    }








    function returnTokenCount() public view returns(uint){
        return _tokenIdCounter.current();
    }
}
