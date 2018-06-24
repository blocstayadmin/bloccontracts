pragma solidity ^0.4.24;

import "./TokenBaseInn.sol";
import "./TokenErrorHandling.sol";

/// @title BlocStay Network INN token lock-up
/// @author James Kennedy - hat-tip to Open-Zeppelin for based code with audited sections
/// @notice Locks up INN tokens for the desired period
/// @dev Releases tokens at the end of the proper period
contract InnLockup {
    using TokenErrorHandling for TokenBaseInn;

    address public endRecipient;  // Address of end recipient
    address public originator;  // Address of lock-up origination
    TokenBaseInn token;  // Token with safety built in
    uint256 public createdTimestamp;
    uint256 public unlockTimestamp;  // Timestamp when release is allowed

    event Received(address endRecipient, uint256 unlockTimestamp);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);

    modifier onlyGenerator {
        require(msg.sender == endRecipient);
        _;
    }

    /// @dev Base call from generator to start this lock-up and tie to an INN token set
    /// @param _originator Origination address of generation
    /// @param _endRecipient The beneficiary of the locked up INN tokens
    /// @param _unlockTimestamp Set for when the INN tokens will be released
    constructor (address _originator, address _endRecipient, uint256 _unlockTimestamp) public {
        require(_unlockTimestamp > block.timestamp);

        originator = _originator;
        endRecipient = _endRecipient;
        unlockTimestamp = _unlockTimestamp;
        createdTimestamp = now;

        emit Received(_endRecipient, _unlockTimestamp);
    }

    /// @dev Do not keep any ETH here
    function() payable public {
        revert();  // This generator is only for INN token lock-up
    }

    function info() public view returns(address, address, uint256, uint256, uint256) {
        return (originator, endRecipient, unlockTimestamp, createdTimestamp, address(this).balance);
    }

    /// @notice Transfers tokens held by timelock to endRecipient
    function release() onlyGenerator public {
        require(block.timestamp >= unlockTimestamp);  // solium would not allow block members
        require(address(this).balance > 0);
        //msg.sender.tryTransfer(endRecipient, address(this).balance);  DEV - Must fix
        emit Withdrew(msg.sender, address(this).balance);
    }

    /// @dev Call to release INN tokens
    function releaseInn(address _tokenContract) onlyGenerator public {
        require(block.timestamp >= unlockTimestamp);
        token = TokenBaseInn(_tokenContract);
        uint256 tokenBalance = token.balanceOf(this);
        token.tryTransfer(endRecipient, tokenBalance);
        emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }
}