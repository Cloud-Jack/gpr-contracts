// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;
import "./GPR_Utils.sol";
import "./GPR_Node.sol";

// GPR - Global Property Registry

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