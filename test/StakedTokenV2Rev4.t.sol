// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "forge-std/Test.sol";
import {IInitializableAdminUpgradeabilityProxy} from "../src/contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {StakedTokenV2Rev4, IERC20, SafeERC20, SafeMath} from "../src/contracts/StakedTokenV2Rev4.sol";
  

contract StakedTokenV2Rev4Test is Test {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant AAVE_MERKLE_DISTRIBUTOR = address(124312);
    address public constant AAVE_LONG_EXECUTOR = 0x79426A1c24B2978D90d7A5070a46C65B07bC4299;
    
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    uint256 public constant AAVE_RESCUE_AMOUNT = 768271398516378775101;
    address public constant STK_AAVE_TOKEN = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    uint256 public constant STK_AAVE_RESCUE_AMOUNT = 107412975567454603565;
    
    // stk token constructor params
    IERC20 public constant stakedToken = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    IERC20 public constant rewardToken = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
    uint256 public constant cooldownSeconds = 864000;
    uint256 public constant unstakeWindow = 172800;
    address public constant rewardsVault = 0x25F2226B597E8F9514B3F68F00f494cF4f286491 ;
    address public constant emissionManager =0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    uint128 public constant distributionDuration = 3155692600;
    string public constant name = "Staked Aave";
    string public constant symbol = "stkAAVE";
    uint8 public constant decimals = 18;

    event TokensRescued(address indexed tokenRescued, address indexed aaveMerkleDistributor, uint256 amountRescued);

    IInitializableAdminUpgradeabilityProxy public proxyStake;
    StakedTokenV2Rev4 stkAaveImpl;
    uint256 public oldRevision;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16369355);

        proxyStake = IInitializableAdminUpgradeabilityProxy(STK_AAVE_TOKEN);
        oldRevision = proxyStake.REVISION();

        stkAaveImpl = new StakedTokenV2Rev4(
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
    }

    function testInitialize() public {
        address[] memory tokens = new address[](2);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = STK_AAVE_TOKEN;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AAVE_RESCUE_AMOUNT;
        amounts[1] = STK_AAVE_RESCUE_AMOUNT;

        vm.expectEmit(true, true, false, true);
        emit TokensRescued(tokens[0], AAVE_MERKLE_DISTRIBUTOR, amounts[0]);
        vm.expectEmit(true, true, false, true);
        emit TokensRescued(tokens[1], AAVE_MERKLE_DISTRIBUTOR, amounts[1]);
        
        vm.prank(AAVE_LONG_EXECUTOR);
        proxyStake.upgradeToAndCall(
            address(stkAaveImpl), 
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address)",
                tokens,
                amounts,
                AAVE_MERKLE_DISTRIBUTOR
            )
        );

        // test that is has initialized correctly
        StakedTokenV2Rev4 stkAave = StakedTokenV2Rev4(STK_AAVE_TOKEN);
        assertEq(stkAave.name(), name);
        assertEq(address(stkAave.STAKED_TOKEN()), address(stakedToken));
        assertEq(address(stkAave.REWARD_TOKEN()), address(rewardToken));
        assertEq(stkAave.COOLDOWN_SECONDS(), cooldownSeconds);
        assertEq(stkAave.UNSTAKE_WINDOW(), unstakeWindow);
        assertEq(stkAave.REWARDS_VAULT(), rewardsVault);
        assertEq(stkAave.EMISSION_MANAGER(), emissionManager);
        assertEq(stkAave.DISTRIBUTION_END(), block.timestamp.add(distributionDuration));
        assertEq(stkAave.symbol(), symbol);
        assertEq(uint256(stkAave.decimals()), uint256(decimals));

        assertEq(stkAave.REVISION(), oldRevision.add(1));

        assertEq(IERC20(AAVE_TOKEN).balanceOf(AAVE_MERKLE_DISTRIBUTOR), AAVE_RESCUE_AMOUNT);
        assertEq(IERC20(STK_AAVE_TOKEN).balanceOf(AAVE_MERKLE_DISTRIBUTOR), STK_AAVE_RESCUE_AMOUNT);
    }

    function testInitializeWhenToBigAmountOfAave() public {
        address[] memory tokens = new address[](2);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = STK_AAVE_TOKEN;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AAVE_RESCUE_AMOUNT + 10 ether;
        amounts[1] = STK_AAVE_RESCUE_AMOUNT;

        vm.expectEmit(true, true, false, true);
        emit TokensRescued(tokens[0], AAVE_MERKLE_DISTRIBUTOR, amounts[0]);
        vm.expectEmit(true, true, false, true);
        emit TokensRescued(tokens[1], AAVE_MERKLE_DISTRIBUTOR, amounts[1]);

        vm.prank(AAVE_LONG_EXECUTOR);
        // we expect empty revert as INVALID_COLLATERALIZATION does not get passed up
        vm.expectRevert(bytes(''));
        proxyStake.upgradeToAndCall(
            address(stkAaveImpl),
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address)",
                tokens,
                amounts,
                AAVE_MERKLE_DISTRIBUTOR
            )
        );

    }
}