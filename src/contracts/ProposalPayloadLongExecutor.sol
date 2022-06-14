// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalPayloadLongExecutor {
    address public LONG_EXECUTOR;

    constructor(address longExecutor) {
        LONG_EXECUTOR = longExecutor;
    }

    function execute() external {
        // here would go the change of admins of all the contracts
    }
}
