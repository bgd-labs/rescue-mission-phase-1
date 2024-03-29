// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";
import { LendToAaveMigrator } from "../src/contracts/LendToAaveMigrator.sol";
import { AaveMerkleDistributor } from "../src/contracts/AaveMerkleDistributor.sol";
import { IInitializableAdminUpgradeabilityProxy } from "../src/contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";

contract LendToAaveMigratorTest is Test {
    // using stdStorage for StdStorage;

    IERC20 public constant AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IERC20 public constant LEND =
        IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
    uint256 public constant LEND_AAVE_RATIO = 100;

    uint256 public constant LEND_TO_MIGRATOR_RESCUE_AMOUNT =
        8007719287288096435418;

    uint256 public constant LEND_TO_LEND_RESCUE_AMOUNT =
        841600717506653731350931;

    uint256 public constant LEND_TO_AAVE_RESCUE_AMOUNT =
        19845132947543342156792;

    address public constant MIGRATOR_PROXY_ADMIN =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    address payable migratorProxyAddress =
        payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);

    LendToAaveMigrator migratorImpl;
    AaveMerkleDistributor aaveMerkleDistributor;
    IInitializableAdminUpgradeabilityProxy migratorProxy;
    LendToAaveMigrator migrator;

    uint256 lendAmountToMigrate = LEND_TO_MIGRATOR_RESCUE_AMOUNT + LEND_TO_LEND_RESCUE_AMOUNT + LEND_TO_AAVE_RESCUE_AMOUNT;

    event AaveTokensRescued(address from, address indexed to, uint256 amount);
    event LendMigrated(address indexed sender, uint256 indexed amount);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16542275);

        aaveMerkleDistributor = new AaveMerkleDistributor();
        migratorImpl = new LendToAaveMigrator(AAVE, LEND, LEND_AAVE_RATIO);
        migratorProxy = IInitializableAdminUpgradeabilityProxy(
            migratorProxyAddress
        );
        migrator = LendToAaveMigrator(migratorProxyAddress);
    }

    function testInitialize() public {
        uint256 beforeTotalLendMigrated = migrator._totalLendMigrated();

        vm.expectEmit(true, true, false, true);
        emit LendMigrated(migratorProxyAddress, lendAmountToMigrate);

        uint256 tokensRescued = lendAmountToMigrate / LEND_AAVE_RATIO;
        vm.expectEmit(false, true, false, true);
        emit AaveTokensRescued(
            migratorProxyAddress,
            address(aaveMerkleDistributor),
            tokensRescued
        );

        vm.prank(MIGRATOR_PROXY_ADMIN);
        migratorProxy.upgradeToAndCall(
            address(migratorImpl),
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,uint256)",
                address(aaveMerkleDistributor),
                LEND_TO_MIGRATOR_RESCUE_AMOUNT,
                LEND_TO_LEND_RESCUE_AMOUNT,
                LEND_TO_AAVE_RESCUE_AMOUNT
            )
        );

        assertEq(
            migrator._totalLendMigrated(),
            beforeTotalLendMigrated + lendAmountToMigrate
        );
        assertEq(LEND.balanceOf(address(migratorProxy)), 0);

        assertEq(AAVE.balanceOf(address(aaveMerkleDistributor)), tokensRescued);
    }

    function testMigrationStarted() public {
        vm.prank(MIGRATOR_PROXY_ADMIN);
        migratorProxy.upgradeToAndCall(
            address(migratorImpl),
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,uint256)",
                address(aaveMerkleDistributor),
                LEND_TO_MIGRATOR_RESCUE_AMOUNT,
                LEND_TO_LEND_RESCUE_AMOUNT,
                LEND_TO_AAVE_RESCUE_AMOUNT
            )
        );

        assertEq(migrator.migrationStarted(), true);
    }

    function testMigrationStartedWithIncorrectAmount() public {
        vm.prank(MIGRATOR_PROXY_ADMIN);
        // we expect empty revert as INCORRECT_BALANCE_RESCUED does not get passed up
        vm.expectRevert(bytes(""));
        migratorProxy.upgradeToAndCall(
            address(migratorImpl),
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,uint256)",
                address(aaveMerkleDistributor),
                LEND_TO_MIGRATOR_RESCUE_AMOUNT + 100 ether,
                LEND_TO_LEND_RESCUE_AMOUNT,
                LEND_TO_AAVE_RESCUE_AMOUNT
            )
        );
    }

    function testMigrateFromLEND() public {
        hoax(MIGRATOR_PROXY_ADMIN);
        migratorProxy.upgradeToAndCall(
            address(migratorImpl),
            abi.encodeWithSignature(
                "initialize(address,uint256,uint256,uint256)",
                address(aaveMerkleDistributor),
                LEND_TO_MIGRATOR_RESCUE_AMOUNT,
                LEND_TO_LEND_RESCUE_AMOUNT,
                LEND_TO_AAVE_RESCUE_AMOUNT
            )
        );

        uint256 beforeLendMigratorAmount = LEND.balanceOf(address(migrator));
        uint256 beforeTotalLendMigrated = migrator._totalLendMigrated();

        uint256 lendAmount = 100 ether;

        deal(address(LEND), address(this), lendAmount);
        LEND.approve(address(migrator), lendAmount);

        vm.expectEmit(true, true, false, true);
        emit LendMigrated(address(this), lendAmount);
        migrator.migrateFromLEND(lendAmount);

        assertEq(AAVE.balanceOf(address(this)), lendAmount / LEND_AAVE_RATIO);
        assertEq(LEND.balanceOf(address(migrator)), beforeLendMigratorAmount);
        assertEq(
            migrator._totalLendMigrated(),
            beforeTotalLendMigrated + lendAmount
        );
    }
}
