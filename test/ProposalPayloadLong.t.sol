// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import { ProposalPayloadLong } from "../src/contracts/ProposalPayloadLong.sol";
import { GovHelpers, IAaveGovernanceV2 } from "aave-helpers/GovHelpers.sol";
import { IERC20 } from "solidity-utils/contracts/oz-common/interfaces/IERC20.sol";

string constant stakedTokenV2Rev4Artifact = "out/StakedTokenV2Rev4.sol/StakedTokenV2Rev4.json";
string constant aaveTokenV2Artifact = "out/AaveTokenV2.sol/AaveTokenV2.json";

contract ProposalPayloadLongTest is Test {
    address public constant LEND = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address public constant STK_AAVE =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    // stk token constructor params
    address public constant stakedToken = AAVE;
    address public constant rewardToken = AAVE;
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

    // test variables
    address public constant AAVE_MERKLE_DISTRIBUTOR = address(1653);
    address internal constant AAVE_WHALE =
        address(0x25F2226B597E8F9514B3F68F00f494cF4f286491);
    uint256 public beforeAaveBalance;
    uint256 public beforeUsdtBalance;
    uint256 public beforeUniBalance;
    uint256 public beforeStkAaveBalance;
    uint256 public beforeAaveOnStkAaveBalance;
    ProposalPayloadLong internal proposalPayload;
    IERC20 aaveToken = IERC20(AAVE);
    IERC20 usdtToken = IERC20(USDT);
    IERC20 uniToken = IERC20(UNI);
    IERC20 stkAaveToken = IERC20(STK_AAVE);

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("ethereum"), 16542275);

        _prepareWhale();

        // get balances before proposal execution
        beforeAaveBalance = aaveToken.balanceOf(AAVE);
        beforeUsdtBalance = usdtToken.balanceOf(AAVE);
        beforeUniBalance = uniToken.balanceOf(AAVE);
        beforeStkAaveBalance = stkAaveToken.balanceOf(STK_AAVE);
        beforeAaveOnStkAaveBalance = aaveToken.balanceOf(STK_AAVE);

        address stkAaveImpl = deployCode(
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

        address aaveTokenV2Impl = deployCode(aaveTokenV2Artifact);

        proposalPayload = new ProposalPayloadLong(
            AAVE_MERKLE_DISTRIBUTOR,
            aaveTokenV2Impl,
            stkAaveImpl
        );
    }

    function testProposal() public {
        address[] memory targets = new address[](1);
        targets[0] = address(proposalPayload);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = GovHelpers.createProposal(
            vm,
            GovHelpers.SPropCreateParams({
                executor: GovHelpers.LONG_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        GovHelpers.passVoteAndExecute(vm, proposalId);
        _validateAaveContractTokensRescued(proposalId);
        _validateStkAaveContractTokensRescued(proposalId);
    }

    function _validateAaveContractTokensRescued(uint256 proposalId) internal {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposalData = GovHelpers
            .getProposalById(proposalId);
        // Generally, there is no reason to have more than 1 payload if using the DELEGATECALL pattern
        address payload = proposalData.targets[0];

        // from payload get data;
        ProposalPayloadLong proposalPayload = ProposalPayloadLong(payload);

        address aaveMerkleDistributor = proposalPayload
            .AAVE_MERKLE_DISTRIBUTOR();

        // we need to test also for the aave sent from stkAave contract
        assertEq(
            IERC20(proposalPayload.AAVE_TOKEN()).balanceOf(
                aaveMerkleDistributor
            ),
            proposalPayload.AAVE_RESCUE_AMOUNT() + (
                proposalPayload.AAVE_STK_RESCUE_AMOUNT()
            )
        );
        assertEq(
            IERC20(proposalPayload.USDT_TOKEN()).balanceOf(
                aaveMerkleDistributor
            ),
            proposalPayload.USDT_RESCUE_AMOUNT()
        );
        assertEq(
            IERC20(proposalPayload.UNI_TOKEN()).balanceOf(
                aaveMerkleDistributor
            ),
            proposalPayload.UNI_RESCUE_AMOUNT()
        );
        assertEq(
            aaveToken.balanceOf(AAVE),
            beforeAaveBalance - proposalPayload.AAVE_RESCUE_AMOUNT()
        );
        assertEq(
            aaveToken.balanceOf(USDT),
            beforeUsdtBalance - proposalPayload.USDT_RESCUE_AMOUNT()
        );
        assertEq(
            aaveToken.balanceOf(UNI),
            beforeUniBalance - proposalPayload.UNI_RESCUE_AMOUNT()
        );
        assertEq(IERC20(LEND).balanceOf(AAVE), 0);
    }

    function _validateStkAaveContractTokensRescued(uint256 proposalId)
        internal
    {
        IAaveGovernanceV2.ProposalWithoutVotes memory proposalData = GovHelpers
            .getProposalById(proposalId);
        // Generally, there is no reason to have more than 1 payload if using the DELEGATECALL pattern
        address payload = proposalData.targets[0];

        // from payload get data;
        ProposalPayloadLong proposalPayload = ProposalPayloadLong(payload);
        address aaveMerkleDistributor = proposalPayload
            .AAVE_MERKLE_DISTRIBUTOR();

        assertEq(
            IERC20(proposalPayload.STK_AAVE_TOKEN()).balanceOf(
                aaveMerkleDistributor
            ),
            proposalPayload.STK_AAVE_RESCUE_AMOUNT()
        );
        assertEq(
            stkAaveToken.balanceOf(STK_AAVE),
            beforeStkAaveBalance - proposalPayload.STK_AAVE_RESCUE_AMOUNT()
        );
        assertEq(
            aaveToken.balanceOf(STK_AAVE),
            beforeAaveOnStkAaveBalance -
                proposalPayload.AAVE_STK_RESCUE_AMOUNT()
        );
    }

    function _prepareWhale() internal {
        deal(AAVE, address(this), 5000000 ether);
        deal(address(this), 1 ether);
        IERC20(AAVE).transfer(AAVE_WHALE, 4000000 ether);
    }
}
