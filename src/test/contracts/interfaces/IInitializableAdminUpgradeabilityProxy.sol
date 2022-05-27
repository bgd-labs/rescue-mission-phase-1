// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInitializableAdminUpgradeabilityProxy {
    function upgradeTo(address newImplementation) external;
}
