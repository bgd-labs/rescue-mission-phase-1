// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import {AaveTokenV2} from "./AaveTokenV2.sol";
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
    

    constructor(address aaveMerkleDistributor) public {
        AAVE_MERKLE_DISTRIBUTOR = aaveMerkleDistributor;
    }

    function execute() external {
        // initialization params
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
        // TODO: should i pass anything to the constructor? if not should I modify 
        // contract constructor???
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
    }
}