// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

import "./GPR_Utils.sol";
import "./GPR_NodeFactory.sol";
import "./GPR_Property.sol";

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