pragma solidity ^0.4.24;

import "./Controllable.sol";

/// @title AuthorizeBuyer
/// @author James Kennedy - hat-tip to Philippe Castonguay for base code
/// @notice Ensure a buyer has cleared KYC/AML checks, as necessary
/// @dev Leverages ECDSA signature parameters and prevent reuse of message on other contract with same owner
contract AuthorizedBuyer is Controllable {
    /// @dev Message must originate with a validated sender
    /// @param _v ECDSA signature parameter v
    /// @param _r ECDSA signature parameters r
    /// @param _s ECDSA signature parameters s
    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) {
        require( isValidAccessMessage(msg.sender,_v,_r,_s) );
        _;
    }

    /// @dev Verifies if message was signed by owner to give access to _add for this contract
    /// Assumes Geth signature prefix
    /// @param _add Address of sender
    /// @param _v ECDSA signature parameter v
    /// @param _r ECDSA signature parameters r
    /// @param _s ECDSA signature parameters s
    /// @return Boolean check on validity of access message
    function isValidAccessMessage(address _add, uint8 _v, bytes32 _r, bytes32 _s) view public returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(this, _add));
        return controller == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s);
    }
}

