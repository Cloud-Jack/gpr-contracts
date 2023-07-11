// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

import "./GPR_Utils.sol";
import "./GPR_NodeFactory.sol";

contract GPR_Property is BaseAccess, BasePayment {
    GPR_NodeFactory private globalFactory;
    address public owner;
    string public location;
    PropertyAddress addressInfo;
    uint public createdAt;
    uint public updatedAt;
    address public issuedBy;
    uint public price = 0;
    address public priceCurrency = address(0);
    bool public isForSell = false;
    address[] public buyRequestsList;
    address public approvedBuyer;

    event GPR_Property_Purchase (address seller, address buyer, uint price);
    event GPR_Property_LocationUpdate (string location);
    event GPR_Property_AddressUpdate (PropertyAddress addr);
    event GPR_Property_PriceUpdate (address priceCurrency, uint price);
    event GPR_Property_OwnerUpdate (address prevOwner, address newOwner);

    constructor(
        GPR_NodeFactory _globalFactory,
        address _owner, 
        string memory _location, 
        string memory _country, 
        string memory _city, 
        string memory _postcode, 
        string memory _localAddress
    ) {
        globalFactory = _globalFactory;
        owner = _owner;
        location = _location;
        addressInfo.country = _country;
        addressInfo.city = _city;
        addressInfo.postcode = _postcode;
        addressInfo.localAddress = _localAddress;
        createdAt = block.timestamp;
        updatedAt = block.timestamp;
        issuedBy = msg.sender;
    }

    function getBuyRequests() public view returns (address[] memory) {
        return buyRequestsList;
    }

    function getGlobalFactoryOwner() public view returns (address) {
        return globalFactory.owner();
    }

    function sendBuyRequest() external {
        require(msg.sender != owner, 'Owner cannot be buyer!');
        require(globalFactory.isUser(msg.sender), 'unknown user address!');
        buyRequestsList.push(msg.sender);
    }

    function hasAddressInRequests(address a) public view returns (bool) {
        bool result = false;
        for (uint i = 0; i < buyRequestsList.length; i++) {
            if (a == buyRequestsList[i]) result = true;
        }
        return result;
    }

    function performBuyRequest() external payable costs(price) {
        require(hasAddressInRequests(msg.sender), 'No such address in buyRequestsList!');
        require(approvedBuyer == msg.sender, 'This address was not approved!');

        address prevOwner = owner;
        owner = msg.sender;
        updatedAt = block.timestamp;
        buyRequestsList = new address[](0);
        approvedBuyer = address(0);
        isForSell = false;
        withdrawTo(prevOwner, address(this).balance);

        emit GPR_Property_Purchase(prevOwner, msg.sender, msg.value);
    }

    function withdrawTo(address _to, uint val) private {
        (bool sent,) = _to.call{value: val}("");
        require(sent, "Failed to send Ether");
    }

    function approveBuyRequest(address a) external onlyBy(owner) {
        require(hasAddressInRequests(msg.sender), 'No such address in buyRequestsList!');
        approvedBuyer = a;
    }

    function setSellParams(uint _price) external onlyBy(owner) {
        require(_price > 0, 'Price must be > 0!');

        price = _price;
        isForSell = true;
        updatedAt = block.timestamp;

        emit GPR_Property_PriceUpdate(priceCurrency, price);
    }

    function setIsForSell(bool _forSell) external onlyBy(owner) {
        isForSell = _forSell;
        updatedAt = block.timestamp;
    }

    function setAddressInfo(
        string memory _country, 
        string memory _city, 
        string memory _postcode, 
        string memory _localAddress
    ) external {
        require(globalFactory.isAdmin(msg.sender));
        addressInfo = PropertyAddress({
            country: _country,
            city: _city,
            postcode: _postcode,
            localAddress: _localAddress
        });
        updatedAt = block.timestamp;

        emit GPR_Property_AddressUpdate(addressInfo);
    }

    function setLocation(string memory _loc) external {
        require(globalFactory.isAdmin(msg.sender));
        location = _loc;
        updatedAt = block.timestamp;

        emit GPR_Property_LocationUpdate(_loc);
    }

    function setOwner(address _newOwner) external {
        require(owner != _newOwner, 'Cannot be the same address');
        require(globalFactory.isAdmin(msg.sender), 'admins only!');
        require(globalFactory.isUser(_newOwner), 'unknown user!');

        address prevOwner = owner; 
        owner = _newOwner;
        updatedAt = block.timestamp;

        emit GPR_Property_OwnerUpdate(prevOwner, _newOwner);
    }
}