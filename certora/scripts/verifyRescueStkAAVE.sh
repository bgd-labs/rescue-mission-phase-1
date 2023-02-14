certoraRun  src/contracts/StakedTokenV2Rev4.sol:StakedTokenV2Rev4 \
            certora/harness/ERC20Dummy.sol:DummyERC20Impl \
    --verify StakedTokenV2Rev4:certora/specs/rescueSTKAAVE.spec \
    --packages solidity-utils/contracts=lib/solidity-utils/src/contracts \
    --link  StakedTokenV2Rev4:STAKED_TOKEN=DummyERC20Impl \
            StakedTokenV2Rev4:REWARD_TOKEN=DummyERC20Impl \
    --solc_map StakedTokenV2Rev4=solc7.5,DummyERC20Impl=solc8.0 \
    --optimistic_loop \
    --cloud \
    --msg "Rescue staked aave"