// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Counter} from "../contracts/Counter.sol";

contract CounterTest {
    Counter internal counter;

    function setUp() public {
        counter = new Counter();
    }

    function test_Increment() public {
        counter.increment();
        require(counter.getNumber() == 1, "increment failed");
    }

    function test_SetNumber(uint256 newNumber) public {
        counter.setNumber(newNumber);
        require(counter.getNumber() == newNumber, "setNumber failed");
    }
}
