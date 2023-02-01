The [AaveMerkleDistributor](./src/contracts/AaveMerkleDistributor.sol) contract is based on [Uniswap MerkleDistributor](https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol).

The logic has not changed, and both use [OpenZeppelin MerkleProof](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol) libs.

The main differences between the two then is the addition of:

- Token rescue methods:
```
function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;
function emergencyEtherTransfer(address to, uint256 amount) external;
```

- Distributions:
The distributions is a system that enables our contract to support multiple rescues by adding new merkleTrees and tokens and encapsulating
the token rescue information in it.
```
/**
* @dev struct that contains the information for a distributionId id
* @param merkleRoot the merkle root of the merkle tree containing account balances available to claim.
* @param claimedBitMap containing the address index to claimed bool.
       This works by storing the indexes 0-255 as 0, 256-511 as 1.
       It is using the bit representation of uint256 to save on gas.
**/
struct Distribution {
    address token;
    bytes32 merkleRoot;
    mapping(uint256 => uint256) claimedBitMap;
}
```

- Batch Claiming
As we can have multiple rescue distributions at the same time, an user could be eligible for rescue in more than one distribution.
With batch claiming said user could claim its rescued tokens with one transaction.
```
/**
* @dev input object with the information to claim a token
* @param index position inside the merkle tree
* @param amount quantity to rescue
* @param merkleProof array of proofs to demonstrate the ownership of the token by account inside the merkletree
* @param distributionId id indicating the distribution of the token inside the merkle distributor (this indicates
         the token to be rescued)
**/
struct TokenClaim {
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
    uint256 distributionId;
}
/**
* @dev Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
* @param claim array of the information of the tokens to claim
*/
function claim(TokenClaim[] calldata claim) external;
```

- Forcing wallet of the owner to be the claimer
By using msg.sender as account, we enforce that only the owners can claim its rescued tokens.
```
bytes32 node = keccak256(abi.encodePacked(claim[i].index, msg.sender, claim[i].amount));
```