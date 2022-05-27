// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IInitializableAdminUpgradeabilityProxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}
