// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LipConqueror is ERC721, ERC721Enumerable, Pausable, Ownable {

    using Strings for uint256;

    // price
    uint256 public constant first1500Price = 9.9 ether;
    uint256 public constant phase1Price = 52 ether;
    uint256 public phase2Price = 52 ether;

    // supply
    uint256 public constant maxLipStickPurchase = 5;
    uint256 public MAX_LIPSTICKS;
    string private _baseURIExtened;

    // states
    bool public isPhase1On = false;
    bool public isPhase2On = false;

    mapping(address => bool) public giveawayRecords;
    mapping(address => bool) public phase2Records;
    mapping(address => uint) public addrMintCount;

    //ERC721("LipConquerorLipstick", "LIPCL")
    constructor(string memory name, string memory symbol, uint256 maxNftSupply) ERC721(name, symbol) {
        MAX_LIPSTICKS = maxNftSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtened;
    }

    function baseURI() public view returns (string memory) {
        return _baseURIExtened;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURIExtened, tokenId.toString()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function reserveLipsticks() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 20; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setBaseURI(string memory baseuri) external onlyOwner {
        _baseURIExtened = baseuri;
    }

    function setGiveawayRecords(address[] calldata addrList) public onlyOwner {
        for (uint i = 0; i < addrList.length; i++) {
            giveawayRecords[addrList[i]] = true;
        }
    }

    function setPhase2Records(address[] calldata addrList) public onlyOwner {
        for (uint i = 0; i < addrList.length; i++) {
            phase2Records[addrList[i]] = true;
        }
    }

    function togglePhase1(bool open) public onlyOwner {
        isPhase1On = open;
    }

    function togglePhase2(bool open) public onlyOwner {
        isPhase2On = open;
    }

    function setPhase2Price(uint256 price) public onlyOwner {
        phase2Price = price;
    }

    receive() external payable {}
    fallback() external payable {}

    function mintStick(uint numberOfTokens) public payable whenNotPaused {
        require(numberOfTokens > 0, "Need at least mint 1 lipstick");
        require(tx.origin == msg.sender, "origin not sender");
        require(numberOfTokens <= maxLipStickPurchase, "Can only mint 5 token at a time");

        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_LIPSTICKS, "Purchase would exceed max supply of nfts");

        uint256 lipstickPrice = 0 ether;
        if(msg.sender != owner()) {
            require( isPhase1On || isPhase2On, "No Sale Phase is ON now" );
            if (!giveawayRecords[msg.sender]) {
                require(addrMintCount[msg.sender] + numberOfTokens <= maxLipStickPurchase, "Max 5 lipsticks can purchase for 1 address");
                if (isPhase1On) {
                    require(supply + numberOfTokens <= 2100, "Purchase would exceed max supply of phase 1");
                    if (supply > 1500) {
                        lipstickPrice = phase1Price;
                    }else {
                        lipstickPrice = first1500Price;
                    }
                }else {
                    require( phase2Records[msg.sender], "Only winner can mint in phase 2" );
                    lipstickPrice = phase2Price;
                    phase2Records[msg.sender] = false;
                }
            }else {
                require(numberOfTokens == 1, "Can only mint 1 lipstick for giveaway");
                giveawayRecords[msg.sender] = false;
            }
        }

        require(lipstickPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        addrMintCount[msg.sender] = addrMintCount[msg.sender] + numberOfTokens;
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_LIPSTICKS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintDrop(address[] calldata addrList) public onlyOwner {
        require(addrList.length > 0, "Need at least send 1 address");

        require(totalSupply() + addrList.length <= MAX_LIPSTICKS, "Send over total supply");

        for (uint i = 0; i < addrList.length; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_LIPSTICKS) {
                _safeMint(addrList[i], mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
       payable(msg.sender).transfer(balance);
    }

    function isPhase2Winner(address _user) public view returns (bool) {
        return phase2Records[_user];
    }

    function isGiveaway(address _user) public view returns (bool) {
      return giveawayRecords[_user];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

