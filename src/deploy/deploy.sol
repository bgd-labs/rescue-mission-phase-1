// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 < 0.9.0;

import "forge-std/Test.sol";
import {AaveTokenV2} from "../contracts/AaveTokenV2.sol";
import {StakedTokenV2Rev4, IERC20 as STKIERC20} from "../contracts/StakedTokenV2Rev4.sol";
import {LendToAaveMigrator} from "../contracts/LendToAaveMigrator.sol";
import {AaveMerkleDistributor} from "../contracts/AaveMerkleDistributor.sol";
import { IERC20 } from "../contracts/dependencies/openZeppelin/IERC20.sol";
import {ProposalPayloadShort} from "../contracts/ProposalPayloadShort.sol";
import {ProposalPayloadLong} from "../contracts/ProposalPayloadLong.sol";


contract Deploy is Test {
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;
    
    address public constant SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    address public constant LONG_EXECUTOR =
        0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7;

    uint256 public constant LEND_AAVE_RATIO = 100;

    // contracts
    LendToAaveMigrator lendToAaveMigratorImpl;
    AaveTokenV2 aaveTokenV2Impl;
    StakedTokenV2Rev4 stakedTokenV2Rev4Impl;
    AaveMerkleDistributor aaveMerkleDistributor;

    // payloads
    ProposalPayloadShort proposalPayloadShort;
    ProposalPayloadLong proposalPayloadLong;

    // staked token deploy params
    STKIERC20 public constant stakedToken = STKIERC20(AAVE);
    STKIERC20 public constant rewardToken = STKIERC20(AAVE);
    uint256 public constant cooldownSeconds = 864000;
    uint256 public constant unstakeWindow = 172800;
    address public constant rewardsVault =
        0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address public constant emissionManager =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    uint128 public constant distributionDuration = 3155692600;
    string public constant name = "Staked Aave";
    string public constant symbol = "stkAAVE";
    uint8 public constant decimals = 18;

    function run () public {
        vm.startBroadcast();
        
        // deploy aave merkle distributor
        aaveMerkleDistributor = new AaveMerkleDistributor();
        aaveMerkleDistributor.transferOwnership(SHORT_EXECUTOR);

        // deploy new implementations
        aaveTokenV2Impl = new AaveTokenV2();
        stakedTokenV2Rev4Impl = new StakedTokenV2Rev4(
            stakedToken,
            rewardToken,
            cooldownSeconds,
            unstakeWindow,
            rewardsVault,
            emissionManager,
            distributionDuration,
            name,
            symbol,
            decimals
        );
        lendToAaveMigratorImpl = new LendToAaveMigrator(
            IERC20(AAVE),
            IERC20(LEND),
            LEND_AAVE_RATIO
        );

        // deploy proposal payloads
        proposalPayloadShort = new ProposalPayloadShort(
            aaveMerkleDistributor,
            address(lendToAaveMigratorImpl)
        );
        proposalPayloadLong = new ProposalPayloadLong(
            address(aaveMerkleDistributor),
            address(aaveTokenV2Impl),
            address(stakedTokenV2Rev4Impl)
        );

        vm.stopBroadcast();
    }
}