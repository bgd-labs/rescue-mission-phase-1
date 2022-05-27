// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import {IERC20} from '../../contracts/dependencies/openZeppelin/IERC20.sol';
import {InitializableAdminUpgradeabilityProxy} from '../../contracts/dependencies/upgradeability/InitializableAdminUpgradeabilityProxy.sol';
import {LendToAaveMigrator} from '../../contracts/LendToAaveMigrator.sol';
import {AaveMerkleDistributor} from '../../contracts/AaveMerkleDistributor.sol';
// import {BaseAdminUpgradeabilityProxy} from '../../contracts/dependencies/upgradeability/BaseAdminUpgradeabilityProxy.sol';
// import {BaseAdminUpgradeabilityProxy} from '../../contracts/dependencies/upgradeability/BaseAdminUpgradeabilityProxy.sol';


contract LendToAaveMigratorTest is Test {
    using stdStorage for StdStorage;

    IERC20 public constant aave = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IERC20 public constant lend = IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
    uint256 public constant lendAaveRatio = 100;

    uint256 public constant lendAmountToMigrate = 8007719287288096435418;

    address public constant MIGRATOR_PROXY_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    address payable migratorProxyAddress = payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);
    
    LendToAaveMigrator migratorImpl;
    AaveMerkleDistributor aaveMerkleDistributor;
    InitializableAdminUpgradeabilityProxy migratorProxy;

    event AaveTokensRescued(address from, address indexed to, uint256 amount);
    event LendMigrated(address indexed sender, uint256 indexed amount);

    function setUp() public {
        aaveMerkleDistributor = new AaveMerkleDistributor();
        migratorImpl = new LendToAaveMigrator(aave, lend, lendAaveRatio);

        migratorProxy = InitializableAdminUpgradeabilityProxy(migratorProxyAddress);
    }

    function testInitialize() public {
        LendToAaveMigrator oldMigrator = LendToAaveMigrator(migratorProxyAddress);
        uint256 beforeTotalLendMigrated = oldMigrator._totalLendMigrated();

        // vm.expectEmit(true, true, false, true);
        // emit LendMigrated(migratorProxyAddress, lendAmountToMigrate);

        // uint256 tokensRescued = lendAmountToMigrate / lendAaveRatio;
        // vm.expectEmit(false, true, false, true);
        // emit AaveTokensRescued(migratorProxyAddress, address(aaveMerkleDistributor), tokensRescued);
        
        vm.startPrank(MIGRATOR_PROXY_ADMIN);
        migratorProxy.upgradeTo(address(migratorImpl));

        migratorProxy.initialize(
            address(migratorImpl),
            MIGRATOR_PROXY_ADMIN,
            abi.encodeWithSignature(
                "initialize(address,uint256)",
                address(aaveMerkleDistributor),
                lendAmountToMigrate
            )
        );

        vm.stopPrank();

        // LendToAaveMigrator newMigrator = LendToAaveMigrator(migratorProxyAddress);

        // assertEq(beforeTotalLendMigrated, beforeTotalLendMigrated + newMigrator._totalLendMigrated());
        // assertEq(IERC20(lend).balanceOf(address(migratorProxy)), 0);
    }
}