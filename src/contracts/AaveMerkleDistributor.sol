// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "./dependencies/contracts/IERC20.sol";
import {MerkleProof} from "./dependencies/contracts/MerkleProof.sol";
import {VersionedInitializable} from './dependencies/upgradeability/VersionedInitializable.sol';
import {IAaveMerkleDistributor} from './interfaces/IAaveMerkleDistributor.sol';

contract AaveMerkleDistributor is VersionedInitializable, IAaveMerkleDistributor {
    // key is the distribution round of a determined token and merkleRoot
    mapping(uint256 => address) public override token;
    mapping(uint256 => bytes32) public override merkleRoot;
    
    // This is a packed array of booleans.
    // TODO: this is public as i did not find a way to modify storage
    // while private on the foundry tests
    mapping(uint256 => mapping(uint256 => uint256)) ClaimedBitMap;

    // address public token;
    // bytes32 public merkleRoot;
    uint256 public constant REVISION = 0x1;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
            return REVISION;
    }

    function initialize(address token_, bytes32 merkleRoot_, uint256 round) public initializer {
        token[round] = token_;
        merkleRoot[round] = merkleRoot_;
    }

    function isClaimed(uint256 index, uint256 round) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[round][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index, uint256 round) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[round][claimedWordIndex] = claimedBitMap[round][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 round) external override {
        require(!isClaimed(index, round), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index, round);
        require(IERC20(token).safeTransfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount, round);
    }
}
