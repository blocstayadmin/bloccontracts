pragma solidity ^0.4.24;

/// @title BlocStay Network Uint SafeMath
/// @author James Kennedy - hat-tip to OpenZeppelin for base template
/// @notice Recommended for all uint math within contracts
/// @dev Throws errors to avoid overflows
library UintMath {
    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return uint result or thrown on overflow
    /// @dev Solely truncates as always safe
    function dividedBy(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return greater number
    function findMax256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return greater number
    function findMax64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return lesser number
    function findMin256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return lesser number
    function findMin64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return uint result or thrown on overflow
    function minus(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return uint result or thrown on overflow
    function plus(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /// @param a First uint to compare
    /// @param b Second uint to compare
    /// @return uint result or thrown on overflow
    function times(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }
}