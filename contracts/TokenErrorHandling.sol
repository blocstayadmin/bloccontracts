pragma solidity ^0.4.24;

import "./TokenBase.sol";

/// @title BlocStay Network Token Protect
/// @author James Kennedy - hat-tip to Open-Zeppelin for the initial codebase, including validation
/// @notice Extends the ERC20 specification to throw errors if a failure is encountered
/// @dev Wrappers around token operations that throw on failure
library TokenErrorHandling {
    function tryTransfer(TokenBase token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function tryTransferFrom(TokenBase token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function tryApprove(TokenBase token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}