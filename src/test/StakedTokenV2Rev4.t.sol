// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import "forge-std/Test.sol";
// import {IERC20} from "../contracts/dependencies/openZeppelin/pre-v8/IERC20.sol";
// import {SafeERC20} from "../contracts/dependencies/openZeppelin/pre-v8/SafeERC20.sol";
import {IInitializableAdminUpgradeabilityProxy} from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import {StakedTokenV2Rev4, IERC20, SafeERC20} from "../contracts/StakedTokenV2Rev4.sol";
  

contract StakedTokenV2Rev4Test is Test {
    using SafeERC20 for IERC20;

    address public constant AAVE_MERKLE_DISTRIBUTOR = address(1);
    address public constant AAVE_LONG_EXECUTOR = 0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7;
    
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    uint256 public constant AAVE_RESCUE_AMOUNT = 372671398516378775101;
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

    IInitializableAdminUpgradeabilityProxy public proxyStake;
    StakedTokenV2Rev4 stkAaveImpl;
    uint256 public oldRevision;

    function setUp() public {
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
    }
}