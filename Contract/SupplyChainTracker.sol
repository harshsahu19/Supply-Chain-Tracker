// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // Product structure to store supply chain data
    struct Product {
        uint256 id;
        string name;
        string currentLocation;
        address currentOwner;
        uint256 timestamp;
        string status; // "manufactured", "shipped", "delivered", "sold"
        bool exists;
    }
    
    // Events for tracking changes
    event ProductCreated(uint256 indexed productId, string name, address indexed owner);
    event ProductTransferred(uint256 indexed productId, address indexed from, address indexed to, string location);
    event ProductStatusUpdated(uint256 indexed productId, string status, string location);
    
    // Storage
    mapping(uint256 => Product) public products;
    mapping(uint256 => address[]) public productHistory; // Track ownership history
    mapping(uint256 => string[]) public locationHistory; // Track location history
    
    uint256 public productCounter;
    address public owner;
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(products[_productId].exists, "Product does not exist");
        _;
    }
    
    modifier onlyProductOwner(uint256 _productId) {
        require(products[_productId].currentOwner == msg.sender, "Only product owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        productCounter = 0;
    }
    
    // Core Function 1: Create a new product in the supply chain
    function createProduct(string memory _name, string memory _initialLocation) public returns (uint256) {
        productCounter++;
        
        products[productCounter] = Product({
            id: productCounter,
            name: _name,
            currentLocation: _initialLocation,
            currentOwner: msg.sender,
            timestamp: block.timestamp,
            status: "manufactured",
            exists: true
        });
        
        // Initialize history arrays
        productHistory[productCounter].push(msg.sender);
        locationHistory[productCounter].push(_initialLocation);
        
        emit ProductCreated(productCounter, _name, msg.sender);
        emit ProductStatusUpdated(productCounter, "manufactured", _initialLocation);
        
        return productCounter;
    }
    
    // Core Function 2: Transfer product to new owner and update location
    function transferProduct(
        uint256 _productId, 
        address _newOwner, 
        string memory _newLocation
    ) public productExists(_productId) onlyProductOwner(_productId) {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != products[_productId].currentOwner, "Cannot transfer to current owner");
        
        address previousOwner = products[_productId].currentOwner;
        
        // Update product details
        products[_productId].currentOwner = _newOwner;
        products[_productId].currentLocation = _newLocation;
        products[_productId].timestamp = block.timestamp;
        products[_productId].status = "shipped";
        
        // Update history
        productHistory[_productId].push(_newOwner);
        locationHistory[_productId].push(_newLocation);
        
        emit ProductTransferred(_productId, previousOwner, _newOwner, _newLocation);
        emit ProductStatusUpdated(_productId, "shipped", _newLocation);
    }
    
    // Core Function 3: Update product status and location
    function updateProductStatus(
        uint256 _productId, 
        string memory _status, 
        string memory _location
    ) public productExists(_productId) onlyProductOwner(_productId) {
        products[_productId].status = _status;
        products[_productId].currentLocation = _location;
        products[_productId].timestamp = block.timestamp;
        
        // Add to location history if location changed
        string[] memory locations = locationHistory[_productId];
        bool locationExists = false;
        for(uint i = 0; i < locations.length; i++) {
            if(keccak256(bytes(locations[i])) == keccak256(bytes(_location))) {
                locationExists = true;
                break;
            }
        }
        if(!locationExists) {
            locationHistory[_productId].push(_location);
        }
        
        emit ProductStatusUpdated(_productId, _status, _location);
    }
    
    // Helper function to get product details
    function getProduct(uint256 _productId) public view productExists(_productId) returns (
        uint256 id,
        string memory name,
        string memory currentLocation,
        address currentOwner,
        uint256 timestamp,
        string memory status
    ) {
        Product memory product = products[_productId];
        return (
            product.id,
            product.name,
            product.currentLocation,
            product.currentOwner,
            product.timestamp,
            product.status
        );
    }
    
    // Get ownership history
    function getOwnershipHistory(uint256 _productId) public view productExists(_productId) returns (address[] memory) {
        return productHistory[_productId];
    }
    
    // Get location history
    function getLocationHistory(uint256 _productId) public view productExists(_productId) returns (string[] memory) {
        return locationHistory[_productId];
    }
    
    // Get total number of products
    function getTotalProducts() public view returns (uint256) {
        return productCounter;
    }
}
