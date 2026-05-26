// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Counter} from "../contracts/Counter.sol";

interface Vm {
    function envUint(string calldata name) external returns (uint256);
    function startBroadcast(uint256 privateKey) external;
    function stopBroadcast() external;
}

contract DeployCounter {
    Vm internal constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external returns (Counter deployed) {
        uint256 deployerPrivateKey = VM.envUint("PRIVATE_KEY");

        VM.startBroadcast(deployerPrivateKey);
        deployed = new Counter();
        VM.stopBroadcast();
    }
}
