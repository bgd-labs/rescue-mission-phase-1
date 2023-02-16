# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes --via-ir
test   :; forge test -vvv

# Utilities
download :; cast etherscan-source --chain ${chain} -d etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

deploy :; forge script scripts/deploy.s.sol:Deploy --rpc-url ${RPC_MAINNET} --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --etherscan-api-key ${ETHERSCAN_API_KEY_ETHEREUM} --gas-estimate-multiplier 100 --verify -vvvv


storage-diff :
	forge inspect etherscan/AaveTokenV2/Contract.sol:AaveTokenV2 storage-layout --pretty > reports/AaveTokenV2_layout.md
	forge inspect src/contracts/AaveTokenV2.sol:AaveTokenV2 storage-layout --pretty > reports/rescue_AaveTokenV2_layout.md
	forge inspect etherscan/StakedTokenV2Rev3/Contract.sol:StakedTokenV2Rev3 storage-layout --pretty > reports/StakedTokenV2Rev3_layout.md
	forge inspect src/contracts/StakedTokenV2Rev4.sol:StakedTokenV2Rev4 storage-layout --pretty > reports/StakedTokenV2Rev4_layout.md
	forge inspect etherscan/LendToAaveMigrator/contracts/token/LendToAaveMigrator.sol:LendToAaveMigrator storage-layout --pretty > reports/LendToAaveMigrator_layout.md
	forge inspect src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator storage-layout --pretty > reports/rescue_LendToAaveMigrator_layout.md
	make git-diff before=reports/AaveTokenV2_layout.md after=reports/rescue_AaveTokenV2_layout.md out=AaveTokenV2_layout_diff
	make git-diff before=reports/StakedTokenV2Rev3_layout.md after=reports/StakedTokenV2Rev4_layout.md out=StakedTokenV2Rev3_layout_diff
	make git-diff before=reports/LendToAaveMigrator_layout.md after=reports/rescue_LendToAaveMigrator_layout.md out=rescue_LendToAaveMigrator_layout_diff