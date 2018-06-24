pragma solidity ^0.4.24;

import "./Controllable.sol";
import "./TokenBase.sol";
import "./TokenErrorHandling.sol";
import "./UintMath.sol";

/// @title TokenBaseInn
/// @author James Kennedy - hat-tip to Open-Zeppelin for base code and
/// FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol and
/// TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
/// @notice Sets basic functions for mintable token to cap
/// @dev Combines several functions for producing INN tokens
contract TokenBaseInn is TokenBase, Controllable  {
    using UintMath for uint256;

    bool public mintingFinished = false;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) public balances;
    string private name;
    string private symbol;
    uint256 totalSupply_;
    uint8 private decimals;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == controller);
        _;
    }

    constructor(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
    * @dev Function to check the amount of tokens that an controller allowed to a spender.
    * @param _controller address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _controller, address _spender) public view returns (uint256) {
        return allowed[_controller][_spender];
    }

    /// @dev
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Retrieve balance of a particular address implementing required function
    /// @param _controller The address of the controller to query
    /// @return Amount controlled by the specified controller
    function balanceOf(address _controller) public view returns (uint256) {
        return balances[_controller];
    }

    /**
     * @dev Decrease the amount of tokens that an controller allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.minus(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /// @dev Stop minting new tokens
    function finishMinting() public onlyController canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an controller allowed to a spender.
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].plus(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /// @dev Function to mint tokens so that tokens are only made when required
    /// @param _to Target address
    /// @param _amount Token amount to mint
    /// @return Boolean that indicates success or failure to mint
    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
        totalSupply_ = totalSupply_.plus(_amount);
        balances[_to] = balances[_to].plus(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /// @dev Total supply
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /// @dev Transfer tokens to a specified address
    /// @param _to Target address
    /// @param _value Target value to transfer
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Transfer from an address to another address
    /// @param _from Originating address
    /// @param _to Target address
    /// @param _value Target value to transfer
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].minus(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}