// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

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