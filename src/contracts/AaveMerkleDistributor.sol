// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IERC20} from "./dependencies/openZeppelin/IERC20.sol";
import {SafeERC20} from "./dependencies/openZeppelin/SafeERC20.sol";
import {Ownable} from "./dependencies/openZeppelin/Ownable.sol";
import {MerkleProof} from "./dependencies/openZeppelin/MerkleProof.sol";
import {IAaveMerkleDistributor} from './interfaces/IAaveMerkleDistributor.sol';

contract AaveMerkleDistributor is Ownable, IAaveMerkleDistributor {
    using SafeERC20 for IERC20;

    /// @dev key is the distribution round of a determined token and merkleRoot
    mapping(uint256 => address) public override token;
    mapping(uint256 => bytes32) public override merkleRoot;
    
    // This is a packed array of booleans.
    // TODO: explain how this works
    mapping(uint256 => mapping(uint256 => uint256)) claimedBitMap;

    uint256 public lastDistributionId = 0;

    function contructor() public {}

    /// @inheritdoc IAaveMerkleDistributor
    function addDistributions(address[] memory tokens, bytes32[] memory merkleRoots) public onlyOwner override {
        require(tokens.length == merkleRoots.length, 'MerkleDistributor: tokens not the same length as merkleRoots'); 
        for(uint i = 0; i < tokens.length; i=i+1) {
            if (lastDistributionId != 0 && i != 0) {
                lastDistributionId += 1;
            }
            
            token[lastDistributionId] = tokens[i];
            merkleRoot[lastDistributionId] = merkleRoots[i];
            
            emit Distribution(tokens[i], merkleRoots[i], lastDistributionId);
        }
    }

    /// @inheritdoc IAaveMerkleDistributor
    function isClaimed(uint256 index, uint256 distributionId) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[distributionId][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @inheritdoc IAaveMerkleDistributor
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 distributionId) external override {
        require(!isClaimed(index, distributionId), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot[distributionId], node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index, distributionId);
        IERC20(token[distributionId]).safeTransfer(account, amount);

        emit Claimed(index, account, amount, distributionId);
    }

    /// @inheritdoc IAaveMerkleDistributor
    function emergencyTokenTransfer(
        address erc20Token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        IERC20(erc20Token).safeTransfer(to, amount);
    }

    /// @inheritdoc IAaveMerkleDistributor
    function emergencyEtherTransfer(address to, uint256 amount) external override onlyOwner {
        _safeTransferETH(to, amount);
    }
    
    /**
    * @dev set claimed as true for index on distributionId
    * @param index indicating which node of the tree needs to be set as true
    * @param distributionId id of the distribution we want to set claimed to true
    */
    function _setClaimed(uint256 index, uint256 distributionId) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[distributionId][claimedWordIndex] = claimedBitMap[distributionId][claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}
