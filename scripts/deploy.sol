// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { LendToAaveMigrator } from "../src/contracts/LendToAaveMigrator.sol";
import { AaveMerkleDistributor } from "../src/contracts/AaveMerkleDistributor.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { ProposalPayloadShort } from "../src/contracts/ProposalPayloadShort.sol";

// artifacts
string constant aaveTokenV2Artifact = "out/AaveTokenV2.sol/AaveTokenV2.json";
string constant stakedTokenV2Rev4Artifact = "out/StakedTokenV2Rev4.sol/StakedTokenV2Rev4.json";
string constant proposalPayloadLongArtifact = "out/ProposalPayloadLong.sol/ProposalPayloadLong.json";

contract Deploy is Test {
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;

    address public constant SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    address public constant LONG_EXECUTOR =
        0x79426A1c24B2978D90d7A5070a46C65B07bC4299;

    uint256 public constant LEND_AAVE_RATIO = 100;

    // contracts
    LendToAaveMigrator lendToAaveMigratorImpl;
    address public aaveTokenV2Impl;
    address public stakedTokenV2Rev4Impl;
    AaveMerkleDistributor aaveMerkleDistributor;

    // payloads
    ProposalPayloadShort proposalPayloadShort;
    address public proposalPayloadLong;

    // staked token deploy params
    IERC20 public constant stakedToken = IERC20(AAVE);
    IERC20 public constant rewardToken = IERC20(AAVE);
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

    function run() public {
        vm.startBroadcast();

        // deploy aave merkle distributor
        aaveMerkleDistributor = new AaveMerkleDistributor();
        console.log("AaveMerkleDistributor:", address(aaveMerkleDistributor));
        aaveMerkleDistributor.transferOwnership(SHORT_EXECUTOR);

        // deploy new implementations
        // We need to use deployCode as solidity version of aaveToken is 0.7.5 and conflicts with other contract versions (0.8.0)
        aaveTokenV2Impl = deployCode(aaveTokenV2Artifact);
        console.log("aaveTokenV2Impl: ", aaveTokenV2Impl);

        stakedTokenV2Rev4Impl = deployCode(
            stakedTokenV2Rev4Artifact,
            abi.encode(
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
            )
        );
        console.log("stakedTokenV2Rev4Impl:", stakedTokenV2Rev4Impl);

        lendToAaveMigratorImpl = new LendToAaveMigrator(
            IERC20(AAVE),
            IERC20(LEND),
            LEND_AAVE_RATIO
        );
        console.log("lendToAaveMigratorImpl:", address(lendToAaveMigratorImpl));

        // deploy proposal payloads
        proposalPayloadShort = new ProposalPayloadShort(
            aaveMerkleDistributor,
            address(lendToAaveMigratorImpl)
        );
        console.log("proposalPayloadShort:", address(proposalPayloadShort));

        proposalPayloadLong = deployCode(
            proposalPayloadLongArtifact,
            abi.encode(
                address(aaveMerkleDistributor),
                aaveTokenV2Impl,
                stakedTokenV2Rev4Impl
            )
        );
        console.log("proposalPayloadLong:", proposalPayloadLong);

        vm.stopBroadcast();
    }
}
