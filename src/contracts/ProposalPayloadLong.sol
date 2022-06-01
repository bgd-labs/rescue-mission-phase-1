// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import {AaveTokenV2} from "./AaveTokenV2.sol";
import {StakedTokenV2Rev4, IERC20} from "./StakedTokenV2Rev4.sol";
import {IInitializableAdminUpgradeabilityProxy} from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";


contract ProposalPayloadLong {
    address public immutable AAVE_MERKLE_DISTRIBUTOR;

    // tokens and amounts to rescue
    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    uint256 public constant AAVE_RESCUE_AMOUNT = 28317484543674044370842;
    address public constant USDT_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public constant USDT_RESCUE_AMOUNT = 15631946764;
    address public constant UNI_TOKEN = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    uint256 public constant UNI_RESCUE_AMOUNT = 110947986090000000000;
    
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

    // stk rescue
    uint256 public constant AAVE_STK_RESCUE_AMOUNT = 372671398516378775101;
    address public constant STK_AAVE_TOKEN = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;
    uint256 public constant STK_AAVE_RESCUE_AMOUNT = 107412975567454603565;
    

    constructor(address aaveMerkleDistributor) public {
        AAVE_MERKLE_DISTRIBUTOR = aaveMerkleDistributor;
    }

    function execute() external {
        // initialization AAVE TOKEN params
        address[] memory tokens = new address[](3);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = USDT_TOKEN;
        tokens[2] = UNI_TOKEN;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = AAVE_RESCUE_AMOUNT;
        amounts[1] = USDT_RESCUE_AMOUNT;
        amounts[2] = UNI_RESCUE_AMOUNT;

        // update AaveTokenV2 implementation with initializer params
        IInitializableAdminUpgradeabilityProxy aaveProxy = 
            IInitializableAdminUpgradeabilityProxy(AAVE_TOKEN);
        AaveTokenV2 aaveTokenImpl = new AaveTokenV2();
        aaveProxy.upgradeToAndCall(
            address(aaveTokenImpl), 
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address)",
                tokens,
                amounts,
                AAVE_MERKLE_DISTRIBUTOR
            )
        );

        // initialization STKAAVE TOKEN params
        address[] memory tokens_stk = new address[](2);
        tokens_stk[0] = AAVE_TOKEN;
        tokens_stk[1] = STK_AAVE_TOKEN;

        uint256[] memory amounts_stk = new uint256[](2);
        amounts_stk[0] = AAVE_STK_RESCUE_AMOUNT;
        amounts_stk[1] = STK_AAVE_RESCUE_AMOUNT;

        // update StakedTokenV2Rev4 implementation with initializer params
        IInitializableAdminUpgradeabilityProxy proxyStake = 
            IInitializableAdminUpgradeabilityProxy(STK_AAVE_TOKEN);
        StakedTokenV2Rev4 stkAaveImpl = new StakedTokenV2Rev4(
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
        proxyStake.upgradeToAndCall(
            address(stkAaveImpl), 
            abi.encodeWithSignature(
                "initialize(address[],uint256[],address)",
                tokens_stk,
                amounts_stk,
                AAVE_MERKLE_DISTRIBUTOR
            )
        );
    
    }
}