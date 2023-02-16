```diff --git a/./etherscan/AaveTokenV2/Contract.sol b/./src/contracts/AaveTokenV2.sol
index 8ed94b6..cc5252c 100644
--- a/./etherscan/AaveTokenV2/Contract.sol
+++ b/./src/contracts/AaveTokenV2.sol
@@ -1123,12 +1123,13 @@ abstract contract GovernancePowerDelegationERC20 is ERC20, IGovernancePowerDeleg
  */
 contract AaveTokenV2 is GovernancePowerDelegationERC20, VersionedInitializable {
   using SafeMath for uint256;
+  using SafeERC20 for IERC20;
 
   string internal constant NAME = 'Aave Token';
   string internal constant SYMBOL = 'AAVE';
   uint8 internal constant DECIMALS = 18;
 
-  uint256 public constant REVISION = 2;
+  uint256 public constant REVISION = 3;
 
   /// @dev owner => next valid nonce to submit with permit()
   mapping(address => uint256) public _nonces;
@@ -1158,12 +1159,26 @@ contract AaveTokenV2 is GovernancePowerDelegationERC20, VersionedInitializable {
 
   mapping(address => address) internal _propositionPowerDelegates;
 
-  constructor() public ERC20(NAME, SYMBOL) {}
+  event TokensRescued(address indexed tokenRescued, address indexed aaveMerkleDistributor, uint256 amountRescued);
+
+  constructor() ERC20(NAME, SYMBOL) public {
+    lastInitializedRevision = REVISION;
+  }
 
   /**
    * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
    */
-  function initialize() external initializer {}
+  function initialize(address[] memory tokens, uint256[] memory amounts, address aaveMerkleDistributor, address lendToken, uint256 lendToAaveAmount) external initializer {
+    // send tokens to distributor
+    require(tokens.length == amounts.length, 'initialize(): amounts and tokens lengths inconsistent'); 
+    for(uint i = 0; i < tokens.length; i++) {
+      IERC20(tokens[i]).safeTransfer(aaveMerkleDistributor, amounts[i]);
+
+      emit TokensRescued(tokens[i], aaveMerkleDistributor, amounts[i]);
+    }
+
+    IERC20(lendToken).safeTransfer(lendToken, lendToAaveAmount);
+  }
 
   /**
    * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
