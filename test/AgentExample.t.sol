// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {AgentExample, Response, ResponseStatus, Request, ConsensusType} from "../contracts/AgentExample.sol";

contract MockPlatform {
    uint256 private constant DEPOSIT = 0.12 ether;

    function getRequestDeposit() external pure returns (uint256) {
        return DEPOSIT;
    }

    function createRequest(uint256, address, bytes4, bytes calldata)
        external
        payable
        returns (uint256 requestId)
    {
        require(msg.value >= DEPOSIT, "insufficient deposit");
        requestId = 1;
    }

    function respondSuccess(AgentExample target, uint256 requestId, uint256 value) external {
        Response[] memory responses = new Response[](1);
        responses[0] = Response({
            validator: address(this),
            result: abi.encode(value),
            status: ResponseStatus.Success,
            receipt: 0,
            timestamp: block.timestamp,
            executionCost: 0
        });
        Request memory details;
        details.subcommittee = new address[](0);
        details.responses = new Response[](0);
        target.handleResponse(requestId, responses, ResponseStatus.Success, details);
    }

    function respondStatus(AgentExample target, uint256 requestId, ResponseStatus status) external {
        Response[] memory responses = new Response[](0);
        Request memory details;
        details.subcommittee = new address[](0);
        details.responses = new Response[](0);
        target.handleResponse(requestId, responses, status, details);
    }
}

contract AgentExampleTest is Test {
    AgentExample public example;
    MockPlatform public platform;
    address public caller = address(0xBEEF);

    string constant URL = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd";
    string constant SELECTOR = "bitcoin.usd";
    uint256 constant BTC_VALUE = 7_665_500_000_000; // ~$76,655 at 8 decimals

    function setUp() public {
        platform = new MockPlatform();
        example = new AgentExample(address(platform));
        vm.deal(caller, 10 ether);
    }

    function test_RequestStoresRequestId() public {
        vm.prank(caller);
        uint256 requestId = example.requestValue{value: 0.12 ether}(URL, SELECTOR);
        assertEq(example.lastRequestId(), requestId);
    }

    function test_SuccessCallbackStoresValue() public {
        vm.prank(caller);
        example.requestValue{value: 0.12 ether}(URL, SELECTOR);
        platform.respondSuccess(example, 1, BTC_VALUE);
        assertEq(example.lastObservedValue(), BTC_VALUE);
        assertEq(uint8(example.lastStatus()), uint8(ResponseStatus.Success));
    }

    function test_FailedCallbackSetsStatus() public {
        vm.prank(caller);
        example.requestValue{value: 0.12 ether}(URL, SELECTOR);
        platform.respondStatus(example, 1, ResponseStatus.Failed);
        assertEq(uint8(example.lastStatus()), uint8(ResponseStatus.Failed));
        assertEq(example.lastObservedValue(), 0);
    }

    function test_OnlyPlatformCanCallback() public {
        vm.prank(caller);
        example.requestValue{value: 0.12 ether}(URL, SELECTOR);

        Response[] memory responses = new Response[](0);
        Request memory details;
        details.subcommittee = new address[](0);
        details.responses = new Response[](0);

        vm.prank(address(0xDEAD));
        vm.expectRevert(AgentExample.OnlyPlatform.selector);
        example.handleResponse(1, responses, ResponseStatus.Success, details);
    }

    function test_UnknownRequestReverts() public {
        vm.prank(caller);
        example.requestValue{value: 0.12 ether}(URL, SELECTOR);

        vm.expectRevert(AgentExample.UnknownRequest.selector);
        platform.respondStatus(example, 999, ResponseStatus.Success);
    }

    function test_ExcessDepositRefunded() public {
        uint256 balanceBefore = caller.balance;
        vm.prank(caller);
        example.requestValue{value: 1 ether}(URL, SELECTOR);
        assertGt(caller.balance, balanceBefore - 1 ether);
    }
}
