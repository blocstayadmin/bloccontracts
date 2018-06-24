pragma solidity ^0.4.24;

/// @title Controllable
/// @author James Kennedy - hat-tip to Open-Zeppelin for base code
/// @notice Basic purpose is to allow for transfer of control to another address or not
/// @dev Designed to be inherited by token contracts
contract Controllable {
    address public controller;
    event ControlTransferred(address indexed previousController, address indexed newController);

    /// @dev First control goes to the contract creator
    constructor() public {
        controller = msg.sender;
    }
    
    /// @dev Protection from non-controller calls
    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    /// @dev Allows transfer of control to a new controller
    /// @param _newController Target address of new controller
    function transferControl(address _newController) public onlyController {
        require(_newController != address(0));
        emit ControlTransferred(controller, _newController);
        controller = _newController;
    }
}