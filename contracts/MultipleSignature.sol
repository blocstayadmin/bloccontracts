pragma solidity ^0.4.24;

/// @title BlocStay Network Multiple Signature
/// @author James Kennedy - hat-tip to Christian Lundvkist
/// @notice Our accounting control to reduce hacking potential and for account control
/// @dev Designed to reduce the attack surface
contract MultipleSignature {
    uint public nonce;                  // (only) mutable state
    uint public threshold;              // immutable state
    mapping (address => bool) isOwner;  // immutable state
    address[] public addrArr;           // immutable state

    /// @param threshold_ Sets the threshold for approval
    /// @param owners_ Array of addresses of the accounts able to authorize execution
    /// @dev Param owners_ must be strictly increasing, in order to prevent duplicates, trailing_ is per style guide
    constructor(uint threshold_, address[] owners_) public {
        require(owners_.length <= 10 && threshold_ <= owners_.length && threshold_ >= 0);

        address lastAdd = address(0);

        for (uint i = 0; i < owners_.length; i++) {
            require(owners_[i] > lastAdd);
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }

        addrArr = owners_;
        threshold = threshold_;
    }

    /// @dev Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    /// @param sigV A hash array
    /// @param sigR A hash array
    /// @param sigS A hash array
    /// @param destination Destination address
    /// @param value Value to be transmitted
    /// @param data Data to be stored
    function execute(uint8[] sigV,
        bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data) public {
        require(sigR.length == threshold);
        require(sigR.length == sigS.length && sigR.length == sigV.length);

        // Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
        bytes32 txHash = keccak256(abi.encodePacked(byte(0x19), byte(0), this, destination, value, data, nonce));

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(txHash, sigV[i], sigR[i], sigS[i]);
            require(recovered > lastAdd && isOwner[recovered]);
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for.
        // The address.call() syntax is no longer recommended, see:
        // https://github.com/ethereum/solidity/issues/2884
        nonce = nonce + 1;
        bool success = false;
        assembly { success := call(gas, destination, value, add(data, 0x20), mload(data), 0, 0) }
        require(success);
    }

    /// @dev Catch-all that will accept ETH
    function () payable public {}
}