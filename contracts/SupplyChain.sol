pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract SupplyChain is ERC721Full, Ownable {
    struct Product {
        string name;
        string origin;
        uint256 timestamp;
        address currentOwner;
    }
    
    struct TransferHistory {
        address from;
        address to;
        uint256 timestamp;
    }

    mapping(uint256 => Product) public products;
    mapping(uint256 => TransferHistory[]) public productHistory;

    enum Role { Manufacturer, Retailer, Consumer }
    mapping(address => Role) public roles;

    event ProductMinted(uint256 tokenId, string name, address owner);
    event ProductTransferred(uint256 tokenId, address from, address to);

    constructor() ERC721Full("SupplyChainProduct", "SCP") public {
        roles[msg.sender] = Role.Manufacturer;
    }

    modifier onlyManufacturer() {
        require(roles[msg.sender] == Role.Manufacturer, "Not a manufacturer");
        _;
    }

    modifier onlyRetailer() {
        require(roles[msg.sender] == Role.Retailer, "Not a retailer");
        _;
    }

    modifier onlyOwnerOfProduct(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not the owner of the product");
        _;
    }

    function addRetailer(address retailer) public onlyOwner {
        roles[retailer] = Role.Retailer;
    }

    // Manufacturer mints the product but assigns it to a Retailer
    function mintProduct(address to, uint256 tokenId, string memory name, string memory origin) public onlyManufacturer {
        require(roles[to] == Role.Retailer, "Recipient must be a retailer");
        _mint(to, tokenId);
        products[tokenId] = Product(name, origin, block.timestamp, to);
        emit ProductMinted(tokenId, name, to);
    }

    // Retailer can transfer products to another Retailer or a Consumer
    function transferProduct(uint256 tokenId, address to) public onlyRetailer onlyOwnerOfProduct(tokenId) {
        productHistory[tokenId].push(TransferHistory(msg.sender, to, block.timestamp));
        safeTransferFrom(msg.sender, to, tokenId);
        products[tokenId].currentOwner = to;
        emit ProductTransferred(tokenId, msg.sender, to);
    }

    function getProductHistory(uint256 tokenId) public view returns (TransferHistory[] memory) {
        return productHistory[tokenId];
    }

    function getProduct(uint256 tokenId) public view returns (string memory, string memory, uint256, address) {
        Product memory product = products[tokenId];
        return (product.name, product.origin, product.timestamp, product.currentOwner);
    }
}
