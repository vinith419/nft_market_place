// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721 {
    AggregatorV3Interface internal priceFeed;
    address public admin;

    mapping(uint256 => uint256) public nftListings;
    event Trade(uint256 indexed tokenId, uint256 price);

    constructor(
        address _priceFeedAddress,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        admin = msg.sender;
    }

    function listNFT(uint256 _tokenId, uint256 _priceInUSD) external {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        nftListings[_tokenId] = _priceInUSD;
    }

    function buyNFT(uint256 _tokenId) external payable {
        uint256 priceInUSD = nftListings[_tokenId];
        require(priceInUSD > 0, "NFT is not listed for sale");
        
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid ETH/USD price");

        uint256 totalPriceInETH = (priceInUSD * msg.value) / uint256(price);
        require(totalPriceInETH == msg.value, "Incorrect ETH amount sent");

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);

        uint256 commission = (msg.value * 10) / 100;
        payable(admin).transfer(commission);

        emit Trade(_tokenId, msg.value);
    }

    function withdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        payable(admin).transfer(address(this).balance);
    }
}
