```diff --git a/./etherscan/StakedTokenV2Rev3/StakedTokenV2Rev3.sol b/./src/contracts/StakedTokenV2Rev4.sol
index 893cc8c..a170671 100644
--- a/./etherscan/StakedTokenV2Rev3/StakedTokenV2Rev3.sol
+++ b/./src/contracts/StakedTokenV2Rev4.sol
@@ -1,3 +1,7 @@
+/**
+ *Submitted for verification at Etherscan.io on 2021-05-05
+*/
+
 /**
  *Submitted for verification at Etherscan.io on 2020-12-10
  */
@@ -1446,7 +1450,7 @@ abstract contract GovernancePowerWithSnapshot is GovernancePowerDelegationERC20
  * @notice Contract to stake Aave token, tokenize the position and get rewards, inheriting from a distribution manager contract
  * @author Aave
  **/
-contract StakedTokenV2Rev3 is
+contract StakedTokenV2Rev4 is
   IStakedAave,
   GovernancePowerWithSnapshot,
   VersionedInitializable,
@@ -1456,7 +1460,7 @@ contract StakedTokenV2Rev3 is
   using SafeERC20 for IERC20;
 
   /// @dev Start of Storage layout from StakedToken v1
-  uint256 public constant REVISION = 3;
+  uint256 public constant REVISION = 4;
 
   IERC20 public immutable STAKED_TOKEN;
   IERC20 public immutable REWARD_TOKEN;
@@ -1497,6 +1501,7 @@ contract StakedTokenV2Rev3 is
   event RewardsClaimed(address indexed from, address indexed to, uint256 amount);
 
   event Cooldown(address indexed user);
+  event TokensRescued(address indexed tokenRescued, address indexed aaveMerkleDistributor, uint256 amountRescued);
 
   constructor(
     IERC20 stakedToken,
@@ -1508,42 +1513,28 @@ contract StakedTokenV2Rev3 is
     uint128 distributionDuration,
     string memory name,
     string memory symbol,
-    uint8 decimals,
-    address governance
+    uint8 decimals
   ) public ERC20(name, symbol) AaveDistributionManager(emissionManager, distributionDuration) {
     STAKED_TOKEN = stakedToken;
     REWARD_TOKEN = rewardToken;
     COOLDOWN_SECONDS = cooldownSeconds;
     UNSTAKE_WINDOW = unstakeWindow;
     REWARDS_VAULT = rewardsVault;
-    _aaveGovernance = ITransferHook(governance);
+    _aaveGovernance = ITransferHook(address(0));
     ERC20._setupDecimals(decimals);
   }
 
   /**
    * @dev Called by the proxy contract
    **/
-  function initialize() external initializer {
-    uint256 chainId;
+  function initialize(address[] memory tokens, uint256[] memory amounts, address aaveMerkleDistributor) external initializer {
+    // send tokens to distributor
+    require(tokens.length == amounts.length, 'stkAave initialization: tokens not the same length as amounts'); 
+    for(uint i = 0; i < tokens.length; i++) {
+      IERC20(tokens[i]).safeTransfer(aaveMerkleDistributor, amounts[i]);
 
-    //solium-disable-next-line
-    assembly {
-      chainId := chainid()
+      emit TokensRescued(tokens[i], aaveMerkleDistributor, amounts[i]);
     }
-
-    DOMAIN_SEPARATOR = keccak256(
-      abi.encode(
-        EIP712_DOMAIN,
-        keccak256(bytes(name())),
-        keccak256(EIP712_REVISION),
-        chainId,
-        address(this)
-      )
-    );
-
-    // Update lastUpdateTimestamp of stkAave to reward users since the end of the prior staking period
-    AssetData storage assetData = assets[address(this)];
-    assetData.lastUpdateTimestamp = 1620594720;
   }
 
   function stake(address onBehalfOf, uint256 amount) external override {
