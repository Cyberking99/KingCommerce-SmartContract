// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

/**
* A multi-vendor ecommerce platform smart contract where multiple vendors can register, list products, and buyers can purchase products directly from those vendors. Each vendor manages their own product inventory, and all payments are processed through the smart contract.

    Basic Functionality:
    1. Vendors: Vendors can register, add products, and remove products.
    2. Buyers: Buyers can browse products and make purchases.
    3. Purchasing: When a buyer makes a purchase, funds are transferred to the vendor.
    4. Admin: Admin can approve or remove vendors.
    5. Withdrawals: Vendors can withdraw their earnings.

**/

contract KingCommerce {

    struct Product {
        uint256 id;
        string productName;
        uint256 productPrice;
        uint256 productStock;
        address vendor;
    }

    struct Vendor {
        uint256 id;
        string vendorName;
        address payable wallet;
        uint256 productCount;
        uint256 balance;
        bool isApproved;
    }

    mapping(address => Vendor) public vendors;
    mapping(uint256 => Product) public products;
    address public admin;
    uint256 public vendorCount;
    uint256 public productCount;

    event VendorRegistered(uint256 id, string vendorName, address vendor);
    event VendorApproved(uint256 id, address vendor);
    event VendorRemoved(uint256 id, address vendor);
    event ProductAdded(uint256 id, string productName, uint256 productPrice, uint256 productStock, address vendor);
    event ProductRemoved(uint256 id, address vendor);
    event Purchase(address buyer, uint256 productId, uint256 quantity, uint256 totalPrice);

    constructor() {
        admin = msg.sender;
        vendorCount = 0;
        productCount = 0;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyApprovedVendor() {
        require(vendors[msg.sender].isApproved == true, "Vendor not approved");
        _;
    }

    function registerVendor(string memory _vendorName) public {
        require(vendors[msg.sender].wallet == address(0), "Vendor already registered");

        vendorCount++;
        vendors[msg.sender] = Vendor(vendorCount, _vendorName, payable(msg.sender), 0, 0, false);

        emit VendorRegistered(vendorCount, _vendorName, msg.sender);
    }

    function approveVendor(address _vendor) public onlyAdmin {
        require(vendors[_vendor].wallet != address(0), "Vendor does not exist");
        require(vendors[_vendor].isApproved == false, "Vendor already approved");

        vendors[_vendor].isApproved = true;

        emit VendorApproved(vendors[_vendor].id, _vendor);
    }

    function removeVendor(address _vendor) public onlyAdmin {
        require(vendors[_vendor].wallet != address(0), "Vendor does not exist");

        delete vendors[_vendor];

        emit VendorRemoved(vendorCount, _vendor);
    }

    function addProduct(string memory _productName, uint256 _productPrice, uint256 _productStock) public onlyApprovedVendor {
        require(_productPrice > 0, "Price must be greater than 0");
        require(_productStock > 0, "Stock must be greater than 0");

        productCount++;
        products[productCount] = Product(productCount, _productName, _productPrice, _productStock, msg.sender);

        vendors[msg.sender].productCount++;

        emit ProductAdded(productCount, _productName, _productPrice, _productStock, msg.sender);
    }

    function removeProduct(uint256 _productId) public onlyApprovedVendor {
        require(products[_productId].vendor == msg.sender, "Only the vendor can remove their products");

        delete products[_productId];

        vendors[msg.sender].productCount--;

        emit ProductRemoved(_productId, msg.sender);
    }

    function buyProduct(uint256 _productId, uint256 _quantity) public payable {
        Product storage product = products[_productId];
        require(_quantity > 0, "Quantity must be greater than 0");
        require(product.productStock >= _quantity, "Not enough stock available");
        require(msg.value == product.productPrice * _quantity, "Incorrect amount sent");

        vendors[product.vendor].balance += msg.value;

        product.productStock -= _quantity;

        emit Purchase(msg.sender, _productId, _quantity, msg.value);
    }

    function withdraw() public onlyApprovedVendor {
        uint256 amount = vendors[msg.sender].balance;
        require(amount > 0, "No balance to withdraw");

        vendors[msg.sender].balance = 0;
        vendors[msg.sender].wallet.transfer(amount);
    }

    function getProducts() public view returns (Product[] memory) {
        Product[] memory productList = new Product[](productCount);

        for (uint256 i = 1; i <= productCount; i++) {
            productList[i - 1] = products[i];
        }

        return productList;
    }
    
    function getVendorProducts(address _vendor) public view returns (Product[] memory) {
        uint256 count = vendors[_vendor].productCount;
        Product[] memory vendorProducts = new Product[](count);
        uint256 counter = 0;

        for (uint256 i = 1; i <= productCount; i++) {
            if (products[i].vendor == _vendor) {
                vendorProducts[counter] = products[i];
                counter++;
            }
        }

        return vendorProducts;
    }
}