pragma solidity ^0.4.24;

import "./InnLockup.sol";

/// @title BlocStay Network INN Lock-up Generator
/// @author James Kennedy - hat-tip to Open-Zeppelin, Radek Ostrowski, and Maciek Zielinski for their codebase
/// as a starting point
/// @notice Generator for all lock-ups, as necessary, for INN tokens
/// @dev A new address and contract are generated for each lock-up
contract InnLockupGenerator {
    mapping(address => address[]) innRecipients;

    function getWallets(address _user) public view returns(address[]) {
        return innRecipients[_user];
    }

    function generateInnLockup(address _owner, uint256 _unlockDate) payable public returns(address innRecipient) {
        innRecipient = new InnLockup(msg.sender, _owner, _unlockDate);  // Generate new inn lockup
        innRecipients[msg.sender].push(innRecipient);  // Track all INN recipient addresses

        // If owner is the same as sender then add innRecipient to sender's innRecipients too.
        if(msg.sender != _owner){
            innRecipients[_owner].push(innRecipient);
        }

        // Send ether from this transaction to the created contract.
        innRecipient.transfer(msg.value);

        emit Created(innRecipient, msg.sender, _owner, now, _unlockDate, msg.value);
    }

    /// @dev Fallback should fail 
    function () public {
        revert();
    }

    event Created(address innRecipient, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}