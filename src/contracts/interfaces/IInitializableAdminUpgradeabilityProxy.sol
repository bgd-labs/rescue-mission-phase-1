// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IInitializableAdminUpgradeabilityProxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    function admin() external returns (address);
}
