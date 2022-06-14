// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";


contract ProposalPayloadLongExecutor {
    address public LONG_EXECUTOR;

    constructor(address longExecutor) {
        LONG_EXECUTOR = longExecutor;
    }

    function execute() external {
        // TODO: here would go the change of admins of all the contracts
        // initialize with IInitializableAdminUpgradeabilityProxy and call chngeAdmin
    }
}
