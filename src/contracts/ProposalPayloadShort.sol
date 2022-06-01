// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {AaveMerkleDistributor} from "./AaveMerkleDistributor.sol";
import {IInitializableAdminUpgradeabilityProxy} from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {LendToAaveMigrator} from "./LendToAaveMigrator.sol";
import {IERC20} from "./dependencies/openZeppelin/IERC20.sol";

/// @title Payload to initialize the tokens rescue phase 1
/// @author BGD
/// @notice Provides an execute function for Aave governance to:
///         - Initialize the AaveMerkleDistributor with the merkleTrees for token rescue for:
///         - AAVE, stkAAVE, USDT, UNI tokens
contract ProposalPayloadShort {
    address public immutable AAVE_MERKLE_DISTRIBUTOR;
    
    // AAVE distribution
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    bytes32 public constant AAVE_MERKLE_ROOT = 0xc2b53b6e06509b53a9ce00ce0ab1955b9dcf607774c46e7268ee1c990436003f;

    // stkAAVE distribution
    address public constant stkAAVE_TOKEN = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    bytes32 public constant stkAAVE_MERKLE_ROOT = 0x71d2b70cb25ea6bbdc276c4b4b9f209c53131d652f962b4d5f6d89fe5a1c6760;

    // USDT distribution
    address public constant USDT_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    bytes32 public constant USDT_MERKLE_ROOT = 0xc7ee13da36bc0398f570e2c50daea6d04645f112371489486655d566c141c156;

    // UNI distribution
    address public constant UNI_TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    bytes32 public constant UNI_MERKLE_ROOT = 0x0d02ecdaab34b26ed6ffa029ffa15bc377852ba0dc0e2ce18927d554ea3d939e;

    // LEND rescue constants
    address public constant MIGRATOR_PROXY_ADDRESS = payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);
    IERC20 public constant LEND = IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
    uint256 public constant LEND_AAVE_RATIO = 100;
    uint256 public constant LEND_TO_MIGRATOR_RESCUE_AMOUNT = 8007719287288096435418;
    uint256 public constant LEND_TO_LEND_RESCUE_AMOUNT = 841600717506653731350931;

    constructor(address aaveMerkleDistributor) public {
        AAVE_MERKLE_DISTRIBUTOR = aaveMerkleDistributor;
    }

    function execute() external {
        AaveMerkleDistributor aaveMerkleDistributor = AaveMerkleDistributor(AAVE_MERKLE_DISTRIBUTOR);

        // initialize first distributions
        address[] memory tokens = new address[](4);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = stkAAVE_TOKEN;
        tokens[2] = USDT_TOKEN;
        tokens[3] = UNI_TOKEN;

        bytes32[] memory merkleRoots = new bytes32[](4);
        merkleRoots[0] = AAVE_MERKLE_ROOT;
        merkleRoots[1] = stkAAVE_MERKLE_ROOT;
        merkleRoots[2] = USDT_MERKLE_ROOT;
        merkleRoots[3] = UNI_MERKLE_ROOT;

        aaveMerkleDistributor.addDistributions(tokens, merkleRoots);
        
        // Deploy new LendToAaveMigrator implementation and rescue LEND
        IInitializableAdminUpgradeabilityProxy lendToAaveMigratorProxy = 
            IInitializableAdminUpgradeabilityProxy(MIGRATOR_PROXY_ADDRESS);

        LendToAaveMigrator lendToAaveMigratorImpl = new LendToAaveMigrator(IERC20(AAVE_TOKEN), LEND, LEND_AAVE_RATIO);

        uint256 totalLendAmountToRescue = LEND_TO_MIGRATOR_RESCUE_AMOUNT + LEND_TO_LEND_RESCUE_AMOUNT;
        lendToAaveMigratorProxy.upgradeToAndCall(
            address(lendToAaveMigratorImpl), 
            abi.encodeWithSignature(
                "initialize(address,uint256)",
                address(aaveMerkleDistributor),
                totalLendAmountToRescue
            )
        );
    }
}