pragma solidity ^0.4.24;

/// @title TokenBase
/// @author James Kennedy - hat-tip to Open-Zeppelin for base code
/// @notice Minimal ERC20 interface
/// @dev Follows guidance of https://github.com/ethereum/EIPs/issues/179 and https://github.com/ethereum/EIPs/issues/20
contract TokenBase {
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
