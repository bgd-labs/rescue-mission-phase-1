using DummyERC20Impl as STAKED_TOKEN1;

methods{
    function STAKED_TOKEN1.balanceOf(address) external returns(uint256) envfree;
    function StakedTokenV2Rev4.totalSupply() external returns(uint256) envfree;
    function _.onTransfer(address, address, uint256) internal => NONDET;
}

// The holding token (stkAAVE) is always backed with a sufficient amount of the staked asset (AAVE)
invariant StkAaveIsBackedByAave()
    totalSupply() <= STAKED_TOKEN1.balanceOf(currentContract)
    {
        preserved with (env e) {
            env e2;
            require e.msg.sender != STAKED_TOKEN1;
            require e.msg.sender != currentContract;
            require REWARDS_VAULT(e2) != currentContract;
        }
    }
