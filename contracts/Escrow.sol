pragma solidity ^0.4.24;

import "./UintMath.sol";
import "./Controllable.sol";

/// @title BlocStay Network Escrow
/// @author James Kennedy - hat-tip to Open-Zeppelin for base code
/// @notice Stores ETH in escrow pending reaching a release trigger
/// @dev Refund issued if escrow conditions not reached and released otherwise
contract Escrow is Controllable {
    using UintMath for uint256;

    enum Phase { PreIco, Ico}
    enum State { Active, Refunding, Closed }

    address public wallet;
    mapping (address => uint256) public deposited;
    Phase public phase;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed investor, uint256 weiAmount);
    event Reopened();

    /// @param _wallet Token target address
    constructor(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
        phase = Phase.PreIco;
    }

    /// @param investor Investor address
    function deposit(address investor) onlyController public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].plus(msg.value);
    }

    function close() onlyController public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance);
        if(phase == Phase.PreIco) {
            phase = Phase.Ico;
            state = State.Active;
            emit Reopened();
        }
    }

    function enableRefunds() onlyController public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    /// @param investor Investor address
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}
