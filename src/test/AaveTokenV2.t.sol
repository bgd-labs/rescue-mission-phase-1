// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "forge-std/Test.sol";
import { IInitializableAdminUpgradeabilityProxy } from "../contracts/interfaces/IInitializableAdminUpgradeabilityProxy.sol";
import { AaveTokenV2, IERC20, SafeMath } from "../contracts/AaveTokenV2.sol";

contract AaveTokenV2Test is Test {
	using SafeMath for uint256;

	address public constant AAVE_MERKLE_DISTRIBUTOR = address(1653);
	address public constant AAVE_PROXY_ADMIN =
		0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7;

	address public constant AAVE_TOKEN =
		0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
	uint256 public constant AAVE_RESCUE_AMOUNT = 28317484543674044370842;
	address public constant USDT_TOKEN =
		0xdAC17F958D2ee523a2206206994597C13D831ec7;
	uint256 public constant USDT_RESCUE_AMOUNT = 15631946764;
	address public constant UNI_TOKEN =
		0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
	uint256 public constant UNI_RESCUE_AMOUNT = 110947986090000000000;

	IERC20 public constant AAVE = IERC20(AAVE_TOKEN);
	IInitializableAdminUpgradeabilityProxy public constant aaveProxy =
		IInitializableAdminUpgradeabilityProxy(AAVE_TOKEN);
	AaveTokenV2 aaveTokenImpl;

	uint256 public oldRevision = aaveProxy.REVISION();

	event TokensRescued(
		address indexed tokenRescued,
		address indexed aaveMerkleDistributor,
		uint256 amountRescued
	);

	function setUp() public {
		vm.createSelectFork(vm.rpcUrl("ethereum"), 15816860);

		aaveTokenImpl = new AaveTokenV2();
	}

	function testInitialize() public {
		address[] memory tokens = new address[](3);
		tokens[0] = AAVE_TOKEN;
		tokens[1] = USDT_TOKEN;
		tokens[2] = UNI_TOKEN;

		uint256[] memory amounts = new uint256[](3);
		amounts[0] = AAVE_RESCUE_AMOUNT;
		amounts[1] = USDT_RESCUE_AMOUNT;
		amounts[2] = UNI_RESCUE_AMOUNT;

		vm.expectEmit(true, true, false, true);
		emit TokensRescued(tokens[0], AAVE_MERKLE_DISTRIBUTOR, amounts[0]);
		vm.expectEmit(true, true, false, true);
		emit TokensRescued(tokens[1], AAVE_MERKLE_DISTRIBUTOR, amounts[1]);
		vm.expectEmit(true, true, false, true);
		emit TokensRescued(tokens[2], AAVE_MERKLE_DISTRIBUTOR, amounts[2]);

		vm.prank(AAVE_PROXY_ADMIN);
		aaveProxy.upgradeToAndCall(
			address(aaveTokenImpl),
			abi.encodeWithSignature(
				"initialize(address[],uint256[],address)",
				tokens,
				amounts,
				AAVE_MERKLE_DISTRIBUTOR
			)
		);

		AaveTokenV2 aaveToken = AaveTokenV2(address(AAVE));
		assertEq(aaveToken.name(), "Aave Token");
		assertEq(aaveToken.symbol(), "AAVE");
		assertEq(uint256(aaveToken.decimals()), uint256(18));

		assertEq(aaveToken.REVISION(), oldRevision.add(1));

		assertEq(AAVE.balanceOf(AAVE_MERKLE_DISTRIBUTOR), AAVE_RESCUE_AMOUNT);
		assertEq(
			IERC20(USDT_TOKEN).balanceOf(AAVE_MERKLE_DISTRIBUTOR),
			USDT_RESCUE_AMOUNT
		);
		assertEq(
			IERC20(UNI_TOKEN).balanceOf(AAVE_MERKLE_DISTRIBUTOR),
			UNI_RESCUE_AMOUNT
		);
	}
}
