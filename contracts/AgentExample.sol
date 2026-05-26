// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// These types mirror the Somnia AgentRequester platform exactly.
// If even one field is missing or reordered, handleResponse will revert on ABI decode
// before your code runs — the callback just silently dies. Copy them verbatim.
// Source: https://docs.somnia.network/agents/invoking-agents/from-solidity
enum ConsensusType {
    Majority,
    Threshold
}

enum ResponseStatus {
    None,
    Pending,
    Success,
    Failed,
    TimedOut
}

struct Response {
    address validator;
    bytes result;       // abi.encode(uint256) for fetchUint — decode with abi.decode(result, (uint256))
    ResponseStatus status;
    uint256 receipt;
    uint256 timestamp;
    uint256 executionCost;
}

struct Request {
    uint256 id;
    address requester;
    address callbackAddress;
    bytes4 callbackSelector;
    address[] subcommittee;
    Response[] responses;
    uint256 responseCount;
    uint256 failureCount;
    uint256 threshold;
    uint256 createdAt;
    uint256 deadline;
    ResponseStatus status;
    ConsensusType consensusType;
    uint256 remainingBudget;
    uint256 perAgentBudget; // must be > 0 or validators skip the request and it times out
}

interface IAgentRequester {
    function getRequestDeposit() external view returns (uint256);

    function createRequest(
        uint256 agentId,
        address callbackAddress,
        bytes4 callbackSelector,
        bytes calldata payload
    ) external payable returns (uint256 requestId);
}

interface IJsonApiAgent {
    function fetchUint(string calldata url, string calldata selector, uint8 decimals)
        external
        returns (uint256);
}

interface IAgentRequesterHandler {
    function handleResponse(
        uint256 requestId,
        Response[] memory responses,
        ResponseStatus status,
        Request memory details
    ) external;
}

/// @notice Minimal Somnia agent-enabled contract.
///
/// The loop: requestValue fires a createRequest to the platform (fire-and-forget),
/// a subcommittee of validators each fetch the URL independently, reach consensus,
/// and the platform calls handleResponse back with the agreed result.
/// No waiting, no polling — your contract just leaves a return address and moves on.
///
/// Replace the URL and selector in agents/request.ts to fetch any public JSON data.
contract AgentExample is IAgentRequesterHandler {
    // Registry ID of the Somnia JSON API Agent (fetches a URL and returns a uint).
    // Source: https://docs.somnia.network/agents/base-agents/json-api-request
    uint256 public constant JSON_API_AGENT_ID = 13_174_292_974_160_097_713;

    // The agent multiplies the JSON value by 10^DECIMALS before returning it.
    // At DECIMALS=8, a BTC price of $76,500 comes back as 7_650_000_000_000.
    // Your threshold comparisons must use the same scale.
    uint8 public constant DECIMALS = 8;

    // getRequestDeposit() is only the operations-reserve floor.
    // Without adding the per-agent reward, perAgentBudget = 0 and runners skip
    // your request — it will time out. Always send floor + pricePerAgent × size.
    uint256 public constant PER_AGENT_EXECUTION_COST = 0.03 ether;
    uint256 public constant SUBCOMMITTEE_SIZE = 3;

    IAgentRequester public immutable PLATFORM;

    uint256 public lastRequestId;
    uint256 public lastObservedValue;
    ResponseStatus public lastStatus;

    event ValueRequested(uint256 indexed requestId, string url, string selector);
    event ValueReceived(uint256 indexed requestId, uint256 value, ResponseStatus status);

    error OnlyPlatform();
    error UnknownRequest();

    constructor(address platform_) {
        PLATFORM = IAgentRequester(platform_);
    }

    /// @notice Post a request to the Somnia JSON API Agent.
    /// @param url      Public JSON endpoint (e.g. a CoinGecko price URL).
    /// @param selector Dot-path into the JSON response (e.g. "bitcoin.usd").
    function requestValue(string calldata url, string calldata selector)
        external
        payable
        returns (uint256 requestId)
    {
        uint256 deposit = PLATFORM.getRequestDeposit() + PER_AGENT_EXECUTION_COST * SUBCOMMITTEE_SIZE;

        // payload tells the agent which function to call and with what arguments
        bytes memory payload = abi.encodeWithSelector(
            IJsonApiAgent.fetchUint.selector, url, selector, DECIMALS
        );

        // address(this) + handleResponse.selector = "call me back here when done"
        requestId = PLATFORM.createRequest{value: deposit}(
            JSON_API_AGENT_ID, address(this), this.handleResponse.selector, payload
        );
        lastRequestId = requestId;

        if (msg.value > deposit) {
            (bool ok,) = payable(msg.sender).call{value: msg.value - deposit}("");
            require(ok, "refund failed");
        }
        emit ValueRequested(requestId, url, selector);
    }

    /// @notice Called by the platform once the validator subcommittee reaches consensus.
    function handleResponse(
        uint256 requestId,
        Response[] memory responses,
        ResponseStatus status,
        Request memory
    ) external override {
        // Without this, anyone could call handleResponse with a fake result.
        if (msg.sender != address(PLATFORM)) revert OnlyPlatform();
        if (requestId != lastRequestId) revert UnknownRequest();

        lastStatus = status;
        if (status == ResponseStatus.Success && responses.length > 0) {
            // responses[0] is the consensus result — already agreed on by the subcommittee
            lastObservedValue = abi.decode(responses[0].result, (uint256));
        }
        emit ValueReceived(requestId, lastObservedValue, status);
    }

    function requiredDeposit() external view returns (uint256) {
        return PLATFORM.getRequestDeposit() + PER_AGENT_EXECUTION_COST * SUBCOMMITTEE_SIZE;
    }

    receive() external payable {}
}
