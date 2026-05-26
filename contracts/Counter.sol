// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Counter {
    uint256 private number;

    event NumberSet(uint256 newNumber);
    event NumberIncremented(uint256 newNumber);

    function setNumber(uint256 newNumber) external {
        number = newNumber;
        emit NumberSet(newNumber);
    }

    function increment() external {
        unchecked {
            number += 1;
        }
        emit NumberIncremented(number);
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}

