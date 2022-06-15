// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";

contract ProposalPayloadLongExecutor {
    address public LONG_EXECUTOR;

    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant ABPT = 0x41A08648C3766F9F9d85598fF102a08f4ef84F84;
    address public constant stkAAVE =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    address public constant stkABPT =
        0xa1116930326D21fB917d5A27F1E9943A9595fb47;

    constructor(address longExecutor) {
        LONG_EXECUTOR = longExecutor;
    }

    function execute() external {
        // TODO: here would go the change of admins of all the contracts
        IInitializableAdminUpgradeabilityProxy aaveProxy = IInitializableAdminUpgradeabilityProxy(
                AAVE
            );
        aaveProxy.changeAdmin(LONG_EXECUTOR);

        IInitializableAdminUpgradeabilityProxy abptProxy = IInitializableAdminUpgradeabilityProxy(
                ABPT
            );
        abptProxy.changeAdmin(LONG_EXECUTOR);

        IInitializableAdminUpgradeabilityProxy stkAaveProxy = IInitializableAdminUpgradeabilityProxy(
                stkAAVE
            );
        stkAaveProxy.changeAdmin(LONG_EXECUTOR);

        IInitializableAdminUpgradeabilityProxy stkAbptProxy = IInitializableAdminUpgradeabilityProxy(
                stkABPT
            );
        stkAbptProxy.changeAdmin(LONG_EXECUTOR);
    }
}
