// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {AgentExample} from "../contracts/AgentExample.sol";

contract DeployAgentExample is Script {
    function run() external {
        address platform = vm.envAddress("SOMNIA_AGENT_PLATFORM");
        vm.startBroadcast();
        AgentExample example = new AgentExample(platform);
        vm.stopBroadcast();
        console.log("AgentExample deployed to:", address(example));
    }
}
