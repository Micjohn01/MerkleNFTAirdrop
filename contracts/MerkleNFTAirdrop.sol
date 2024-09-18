// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Importing the required OpenZeppelin libraries for ERC20 interface, Merkle Proof verification, and BitMaps utility.
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// Custom errors for the contract, used instead of revert messages to save gas.
error NotOwner();
error AirDropAlreadyClaimed();
error ClaimingTimeAlreadyPassed();
error InvalidProof();
error AirdropIsStillActive();
error YouDoNotOwnRequiredNFT();

contract MerkleNFTAirdrop {
    // Address of the contract owner, immutable as it is set only once during contract deployment.
    address public immutable owner;

    // Address of the ERC20 token to be airdropped, immutable as it is set during deployment.
    IERC20 public immutable tokenAddress;
    IERC721 public constant boredApeNFT =
        IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

    // The Merkle root for the airdrop, used to verify the eligibility of claimers.
    bytes32 public merkleRoot;

    // Timestamp indicating the end of the airdrop period.
    uint256 airdropEndingTime;

    // Bitmap structure to track which airdrop slots have already been claimed.
    BitMaps.BitMap internal listOfAirdropSlots;

    // Event emitted when a successful airdrop claim is made.
    event ClaimSuccssful(address indexed claimer, uint256 amount);

    /**
     * @dev Constructor that sets up the token address, Merkle root, and airdrop end time.
     * @param _tokenAddress The address of the ERC20 token being airdropped.
     * @param _merkleRoot The Merkle root used to verify airdrop claims.
     * @param _endingTimeInsec The duration (in seconds) until the airdrop ends.
     */
    constructor(
        address _tokenAddress,
        bytes32 _merkleRoot,
        uint256 _endingTimeInsec
    ) {
        tokenAddress = IERC20(_tokenAddress); // Initialize the token address.
        owner = msg.sender; // Set the contract deployer as the owner.
        merkleRoot = _merkleRoot; // Initialize the Merkle root.
        airdropEndingTime = block.timestamp + _endingTimeInsec; // Set the airdrop end time.
    }

    /**
     * @dev Function to claim tokens from the airdrop.
     * @param proof The Merkle proof that verifies the claimer's eligibility.
     * @param index The index of the claimer in the Merkle tree.
     * @param amount The amount of tokens to claim.
     */
    function claimAirDrop(
        bytes32[] calldata proof,
        bytes32 leaf,
        uint256 index,
        uint256 amount
    ) external {
        if (!(boredApeNFT.balanceOf(msg.sender) > 0)) {
            revert YouDoNotOwnRequiredNFT();
        }
        if (
            BitMaps.get(listOfAirdropSlots, index)
        ) // Revert if the tokens at the given index have already been claimed.
        {
            revert AirDropAlreadyClaimed();
        }

        // Revert if the claiming period has ended.
        if (!canStillClaim()) {
            revert ClaimingTimeAlreadyPassed();
        }

        // Verify the claimer's proof before allowing them to claim tokens.
        verifyProof(proof, leaf, index, amount, msg.sender);

        // Mark the index as claimed in the bitmap.
        BitMaps.setTo(listOfAirdropSlots, index, true);

        // Transfer the claimed amount of tokens to the claimer.
        tokenAddress.transfer(msg.sender, amount);

        // Emit an event to log the successful claim.
        emit ClaimSuccssful(msg.sender, amount);
    }

    /**
     * @dev Internal function to check if the caller is the owner of the contract.
     * Reverts with a custom error if the caller is not the owner.
     */
    function _onlyOwner() private view {
        if (msg.sender != owner) {
            revert NotOwner();
        }
    }

    /**
     * @dev Internal function to verify the Merkle proof for the claimer's eligibility.
     * @param proof The Merkle proof provided by the claimer.
     * @param index The index of the claimer in the Merkle tree.
     * @param amount The amount of tokens the claimer is entitled to.
     * @param addr The address of the claimer.
     */
    function verifyProof(
        bytes32[] memory proof,
        bytes32 leaf,
        uint256 index,
        uint256 amount,
        address addr
    ) private view {
        // Compute the leaf node in the Merkle tree by hashing the claimer's address, index, and amount.
        // bytes32 leaf = keccak256(abi.encodePack(addr, index, amount));
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root

        // Revert if the proof does not match the Merkle root.
        if (computedHash != merkleRoot) {
            revert InvalidProof();
        }
    }

    /**
     * @dev Internal view function to check if the airdrop claim period is still active.
     * @return True if the airdrop is still active, otherwise false.
     */
    function canStillClaim() private view returns (bool) {
        if (block.timestamp < airdropEndingTime) {
            return true;
        }
        return false;
    }
}