using DummyERC20Impl as LEND1;
using DummyERC20Impl2 as AAVE1;
using AaveTokenV2 as AAVE_ORIG;

methods{
    function LEND1.balanceOf(address) external returns (uint256) envfree;
    function AAVE1.balanceOf(address) external returns (uint256) envfree;
    function LEND1.totalSupply() external returns (uint256) envfree;
    function LEND_AAVE_RATIO() external returns (uint256) envfree;
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.onTransfer(address, address, uint256) external => NONDET;
}

ghost uint256 lend_to_aave;
// {
//     init_state axiom lend_to_aave == 0;
// }

// All the LEND that wasn’t sent for swap in the migrator must be fully collateralised with AAVE
invariant LendIsBackedByAave()
    ( (LEND1.totalSupply() - LEND1.balanceOf(LEND1)) ) / LEND_AAVE_RATIO() <= to_mathint(AAVE1.balanceOf(currentContract))
    {
        preserved with (env e){
            require e.msg.sender != LEND1;
            require e.msg.sender != AAVE1;
        }
    }

// // All the LEND that wasn’t sent for swap in the migrator must be fully collateralised with AAVE
// rule LendIsBackedByAave(env e, method f){
//     require e.msg.sender != LEND1;
//     require e.msg.sender != AAVE1;
//     require ( (LEND1.totalSupply() - LEND1.balanceOf(LEND1)) ) / LEND_AAVE_RATIO() <= AAVE1.balanceOf(currentContract);

//     calldataarg args;
//     f(e, args);

//     assert ( (LEND1.totalSupply() - LEND1.balanceOf(LEND1)) ) / LEND_AAVE_RATIO() <= AAVE1.balanceOf(currentContract);
// }

// Shows that the property is preserved for also for initialized after AAVE.initialized is called with the same arg
rule LendIsBackedByAaveIncInitialize(env e, method f){
    require e.msg.sender != LEND1;
    require e.msg.sender != AAVE1;
    require LEND_AAVE_RATIO() !=0;
    require ( (LEND1.totalSupply() - LEND1.balanceOf(LEND1)) ) / LEND_AAVE_RATIO() <= to_mathint(AAVE1.balanceOf(currentContract));
    
    if (f.selector == sig:initialize(address, uint256, uint256, uint256).selector){
        address aaveMerkleDistributor; uint256 lendToMigratorAmount; uint256 lendToLendAmount; uint256 lendToAaveAmount;
        initialize(e, aaveMerkleDistributor, lendToMigratorAmount, lendToLendAmount, lendToAaveAmount);
        address lendToken = LEND1;
        address[] tokens; uint256[] amounts;
        env e2;
        AAVE_ORIG.initialize(e, tokens, amounts, aaveMerkleDistributor, lendToken, lendToAaveAmount);   
    }
    else {
        calldataarg args;
        f(e, args);
    }

    assert ( (LEND1.totalSupply() - LEND1.balanceOf(LEND1)) ) / LEND_AAVE_RATIO() <= to_mathint(AAVE1.balanceOf(currentContract));
}
