certoraRun  src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator \
            certora/harness/ERC20Dummy.sol:DummyERC20Impl \
            certora/harness/ERC20Dummy2.sol:DummyERC20Impl2 \
            src/contracts/AaveTokenV2.sol \
    --verify LendToAaveMigrator:certora/specs/rescueLendMigrator.spec \
    --packages solidity-utils/contracts=lib/solidity-utils/src/contracts \
    --link  LendToAaveMigrator:LEND=DummyERC20Impl \
            LendToAaveMigrator:AAVE=DummyERC20Impl2 \
    --solc_map LendToAaveMigrator=solc8.0,DummyERC20Impl=solc8.0,DummyERC20Impl2=solc8.0,AaveTokenV2=solc7.5 \
    --optimistic_loop \
    --cloud \
    --rule $1 \
    --msg "Rescue Lend Migrator $1"