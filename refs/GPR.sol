// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

// GPR - Global Property Registry

contract BaseAccess {
    modifier onlyBy(address addr) {
        require(msg.sender == addr, 'Unauthorized!');
        _;
    }
}

contract BasePayment {
    modifier costs(uint amount) {
        require(msg.value >= amount, 'Insufficient amount!');
        _;
    }
}

struct PropertyAddress {
    string country;
    string city;
    string postcode;
    string localAddress;
}

contract GPR_NodeFactory is BaseAccess {
    address public owner;
    string public name;
    string public url;
    address[] public admins;
    mapping(address => bool) private adminsMap;
    mapping(address => bool) public users;
    uint public lastNodeID = 0;

    constructor( string memory _name, string memory _url) {
        name = _name;
        url = _url;
        owner = msg.sender;
        adminsMap[msg.sender] = true;
        admins.push(msg.sender);
    }

    event GPR_NodeFactory_NewNode (address nodeAddress);
    event GPR_NodeFactory_AdminsUpdate (address[]);
    event GPR_NodeFactory_UsersUpdate (address addr, bool value);

    function setName(string memory _name) external onlyBy(owner) {
        name = _name;
    }

    function setUrl(string memory _url) external onlyBy(owner) {
        url = _url;
    }

    function getAdmins() public view returns(address[] memory) {
        return admins;
    }

    function isAdmin(address a) public view returns(bool) {
        return adminsMap[a];
    }

    function addAdmin(address a) external onlyBy(owner) {
        require(adminsMap[a] == false, 'address exists!');
        adminsMap[a] = true;
        admins.push(a);
        emit GPR_NodeFactory_AdminsUpdate(admins);
    }

    function removeAdmin(uint _index, address _address) external onlyBy(owner) {
        address addr = admins[_index];
        require(addr == _address, '_index must point to _address!');
        require(addr != owner, 'Owner cannot be deleted!');
        admins[_index] = admins[admins.length - 1];
        admins.pop();
        delete adminsMap[_address];
        emit GPR_NodeFactory_AdminsUpdate(admins);
    }

    function setUser(address addr, bool value) external {
        require(isAdmin(msg.sender), 'only for admins!');
        users[addr] = value;
        emit GPR_NodeFactory_UsersUpdate(addr, value);
    }

    function isUser(address user) public view returns(bool) {
        return users[user];
    }

    function createNode() external onlyBy(owner) returns (address) {
        lastNodeID++;
        address newNodeAddress = address(new GPR_Node(lastNodeID, this));
        emit GPR_NodeFactory_NewNode(newNodeAddress);
        return newNodeAddress;
    }
}

contract GPR_Node is BaseAccess {
    GPR_NodeFactory private globalFactory;
    uint public nodeID;
    address[] internal properties;
    uint16 limit = 2000;

    constructor(uint _nodeID, GPR_NodeFactory _globalFactory) {
        globalFactory = _globalFactory;
        nodeID = _nodeID;
    }

    event GPR_Node_NewProperty (address propertyAddress);

    function createProperty(
        address _owner, 
        string memory _location, 
        string memory _country, 
        string memory _city, 
        string memory _postcode, 
        string memory _localAddress
    ) external returns(address) {
        require(limit > properties.length, 'Limit has been reached!');
        require(globalFactory.isAdmin(msg.sender), 'Only for admins!');
        require(globalFactory.isUser(_owner), 'unknown user!');
        address newPropertyAddr = address(new GPR_Property(globalFactory, _owner, _location, _country, _city, _postcode, _localAddress));
        properties.push(newPropertyAddr);
        emit GPR_Node_NewProperty(newPropertyAddr);
        return newPropertyAddr;
    }

    function getProperties() public view returns (address[] memory) {
        return properties;
    }

    function getGlobalFactoryAddress() public view returns (address){
        return address(globalFactory);
    }
}

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