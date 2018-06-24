pragma solidity ^0.4.24;

import "./AuthorizedBuyer.sol";
import "./Escrow.sol";
import "./InnLockup.sol";
import "./TokenBaseInn.sol";
import "./TokenErrorHandling.sol";
import "./UintMath.sol";

/// @title InnTokenProduce
/// @author James Kennedy - hat-tip to Open-Zeppelin for base code and https://github.com/sandeeppanda92
/// @notice Produce INN tokens whether for pre-ICO/ICO or internal with cap, escrow and time lock
/// @dev Mash-up of existing best practices
contract InnTokenProduce is AuthorizedBuyer {
    using UintMath for uint256;
    
    address private targetAddress;  // Target address for transfer; could be another contract or a wallet
    bool private goalReachedIco;  // Flag for soft cap goal fo ICO
    bool private goalReachedPreIco;  // Flag for soft cap goal for pre-ICO
    bool private isFinalized = false;
    enum CapCheck { PreIco, Ico, Community, Company, Team }
    enum IcoStage { PreIco, Ico }
    enum TokenPurpose { Community, Company, Team }
    Escrow public escrow;  // Address to hold any tokens pending escrow release or return
    IcoStage private stage = IcoStage.PreIco;  // Default case is PreIco
    string private name;  // Name of the generated base INN token
    string private symbol;  // Symbol for the generated base INN token
    TokenBaseInn public token;  // Token for production through sale/vesting/minting
    uint256 private bonusInnQty;  // Bonus INN tokens during pre-ICO
    uint256 private bonusInnPercent;  // Bonus percent of INN for a production calculation
    uint256[] private bonusStartArray;  // Array of start dates for bonus
    uint256[] private bonusEndArray;  // Array of end dates for bonus
    uint256 private capWeiIco;  // Cap for ICO round in dollars
    uint256 private capWeiPreIco;  // Cap for Pre-ICO round in dollars
    uint256[] private closingTimeArray;  // Closing times for phases
    uint256 private goalPreIcoBonus;  // Optional bonus for achieving pre-ICO goal
    uint256 private goalWeiRaiseIco;  // Soft cap goal for ICO
    uint256 private goalWeiRaisePreIco;  // Soft cap goal for Pre-ICO
    uint256 private innTokenIcoReleaseDate;  // Release date for INN tokens locked up during ICO
    uint256 private innTokensToProduce;  // Amount of INN tokens per Eth
    uint256[] private miscConstructorArray;  // Miscellaneous variable array to fix Stack too Deep Error
    uint256[] private openingTimeArray;  // Opening times for phases
    uint256 private rate;  // INN/wei
    uint256 private tokensProducedCommunity;  // Tokens produced for community
    uint256 private tokensProducedCompany;  // Tokens produced for company
    uint256 private tokensProducedIco;  // Tokens produced in ICO
    uint256 private tokensProducedPreIco;  // Tokens produced in pre-ICO
    uint256 private tokensProducedTeam;  // Tokens produced for the team
    uint256 private weiRaised; // Wei raised in total
    uint256 private weiRaisedIco;  // Wei raised in ICO
    uint256 private weiRaisedPreIco;  // Wei raised pre-ICO
    uint32[] private capConstructorArray;  // To fix a Stack too deep error
    uint32 private capRecipient;  // Cap for a recipient
    uint32 private capTokens;  // Cap for production of tokens
    uint32 private capTokensIco;  // Cap for ICO
    uint32 private capTokensPreIco;  // Cap for Pre-ICO
    uint32 private capTokensCommunityReserve;  // Cap for community reserve fund
    uint32 private capTokensCompanyReserve;  // Cap for company reserve fund
    uint32 private capTokensTeam;  // Cap for team, advisors and opportunities
    uint32[] private closeGoalBonusArray;  // INN bonus for being the transaction that closes out the phase goal
    uint32 private dollarsRaisedIco;  // Rough calculation of dollars raised based on wei per phase
    uint32 private dollarsRaisedPreIco;  // Rough calculation of dollars raised based on wei per phase
    uint32 private dollarWei;  // Rough number of dollar "wei" per wei
    uint8[] private bonusInnPercentArray;  // Array of bonus percent amounts in INN
    uint8 private decimals; // Number of decimals for the associated INN token

    event FinishCallFailed(uint256 tokensProducedCommunity, uint256 tokensProducedCompany, uint256 tokensProducedTeam,
        uint256 tokensProducedIco, uint256 tokensProducedPreIco, IcoStage stage);
    event ProductionSettings(uint256[] settings);  // Emit the final settings for the contract

    /// @dev Production can be finalized
    event Finalized();

    /// @dev Production has been completed
    event Produced(address _innRecipient, uint256 _produced);

    /// @dev Event for token production logging
    /// @param requestor Party who wants to produce tokens
    /// @param innRecipient Party who received the produced tokens
    /// @param value Weis paid for production
    /// @param amount Amount of tokens produced
    event TokenProduction(address indexed requestor, address indexed innRecipient, uint256 value, uint256 amount);

    /// @dev Ensure that bonus arrays have equal length
    modifier arraysHaveEqualLength {
        require(bonusStartArray.length == bonusEndArray.length && bonusEndArray.length == bonusInnPercentArray.length);
        _;
    }

    /// @dev Requires time range for pre-ICO, ICO bonuses and production
    modifier isOpenPeriod {
        if(stage == IcoStage.PreIco) {  // solium error while using block below
            require(block.timestamp >= openingTimeArray[0] && block.timestamp <= closingTimeArray[0]);
        } else {
            require(block.timestamp >= openingTimeArray[1] && block.timestamp <= closingTimeArray[1]);
        }
        _;
    }

    /// @dev Ensure that the recipient is not capped
    modifier recipientNotCapped(address innRecipient) {
        require(innRecipient != address(0));
        require(token.balanceOf(innRecipient).plus(msg.value.times(rate)) <= capRecipient);
        _;
    }
    
    /// @dev Ensure hard cap not exceeded for a phase based on daily wei set
    modifier tokenPhaseHardCapNotExceeded {
        if(stage == IcoStage.PreIco) {
            require(weiRaised.plus(msg.value) <= capWeiPreIco);
        } else {
            require(weiRaised.plus(msg.value) <= capWeiIco);
        }
        _;
    }

    /// @dev Ensure token production caps for a phase will not be exceeded
    modifier tokenPhaseProductionCapNotExceeded {
        require(msg.value > 0);
        innTokensToProduce = _getTokenAmount(msg.value);
        
        if(stage == IcoStage.PreIco) {
            require(tokensProducedPreIco.plus(rate.times(msg.value)) <= capTokensPreIco);
            uint256 onePercent = innTokensToProduce.dividedBy(100);
            bonusInnQty = _calculateBonus().times(onePercent);
            require(tokensProducedPreIco.plus(innTokensToProduce).plus(bonusInnQty) <= capTokensPreIco);
        } else {
            require(tokensProducedIco.plus(rate.times(msg.value)) <= capTokensIco);
        }
        _;
    }

    /// @dev Ensure token production caps for an internal type are not exceeded
    /// @param purpose Bucket of the token
    modifier tokenTypeProductionNotExceeded(TokenPurpose purpose) {
        require(purpose == TokenPurpose.Community || purpose == TokenPurpose.Company || purpose == TokenPurpose.Team);
        if(purpose == TokenPurpose.Community) {
            require(tokensProducedCommunity.plus(rate.times(msg.value)) <= capTokensCommunityReserve);
        } else if (purpose == TokenPurpose.Company) {
            require(tokensProducedCompany.plus(rate.times(msg.value)) <= capTokensCompanyReserve);
        } else if (purpose == TokenPurpose.Team) {
            require(tokensProducedTeam.plus(rate.times(msg.value)) <= capTokensTeam);
        } else {
            revert();
        }
        _;
    }

    /// @dev Constructor passing in production parameters
    /// @param _bonusStartArray Array of start times for bonus levels
    /// @param _bonusEndArray Array of end times for bonus levels
    /// @param _bonusInnPercentArray Array of bonuses per relevant time period, in percent
    /// @param _capConstructorArray Array to fix a Stack too Deep error
    /// @param _closeGoalBonusArray Set of bonuses for closing out goals of various phases
    /// @param _closingTimeArray Closing time array for closing time per phase
    /// @param _decimals Decimals for the INN token
    /// @param _miscConstructorArray Part of fix for Stack too Deep error
    /// @param _name Name of the INN token
    /// @param _openingTimeArray Opening time array for opening time per phase
    /// @param _symbol Symbol for the INN token
    /// @param _targetAddress Address to send produced INN tokens
    constructor(uint256[] _bonusStartArray, uint256[] _bonusEndArray, uint8[] _bonusInnPercentArray,
        uint32[] _capConstructorArray, uint32[] _closeGoalBonusArray, uint256[] _closingTimeArray,
        uint8 _decimals, uint256[] _miscConstructorArray, string _name, uint256[] _openingTimeArray,
        string _symbol, address _targetAddress) public {
        require(_miscConstructorArray[0] > 0);  // _capWeiIco
        require(_miscConstructorArray[1] > 0);  // _capWeiPreIco
        require(_capConstructorArray[0] > 0);  // _capRecipient
        require(_capConstructorArray[1] > 0);  // _capTokensIco
        require(_capConstructorArray[2] > 0);  // _capTokensPreIco
        require(_capConstructorArray[3] > 0);  // _capTokensCommunityReserve
        require(_capConstructorArray[4] > 0);  // _capTokensCompanyReserve
        require(_capConstructorArray[5] > 0);  // _capTokensTeam
        require(_closingTimeArray[0] >= _openingTimeArray[0]);
        require(_openingTimeArray[1] >= _closingTimeArray[0]);
        require(_closingTimeArray[1] >= _openingTimeArray[1]);
        require(_miscConstructorArray[2] > 0);  // _goalWeiRaiseIco
        require(_miscConstructorArray[3] > 0);  // _goalWeiRaisePreIco
        require(_miscConstructorArray[2].plus(_miscConstructorArray[3]) <=
            _miscConstructorArray[0].plus(_miscConstructorArray[1]));
        require(_miscConstructorArray[5] >= block.timestamp);  // Solium (block) _innTokenIcoReleaseDate
        require(bytes(_name).length != 0);  // Check for string length
        require(_openingTimeArray[0] >= block.timestamp);  // Solium not allowed (block)
        require(_miscConstructorArray[6] > 0);  // _rate
        require(bytes(_symbol).length != 0);  // Check for string length
        require(_targetAddress != address(0));

        bonusStartArray = _bonusStartArray;
        bonusEndArray = _bonusEndArray;
        bonusInnPercentArray = _bonusInnPercentArray;
        capWeiIco = _miscConstructorArray[0];
        capWeiPreIco = _miscConstructorArray[1];
        capRecipient = _capConstructorArray[0];
        capTokensIco = _capConstructorArray[1];
        capTokensPreIco = _capConstructorArray[2];
        capTokensCommunityReserve = _capConstructorArray[3];
        capTokensCompanyReserve = _capConstructorArray[4];
        capTokensTeam = _capConstructorArray[5];
        capTokens = _capConstructorArray[1] + _capConstructorArray[2] + _capConstructorArray[3] +
            _capConstructorArray[4] + _capConstructorArray[5];
        closeGoalBonusArray = _closeGoalBonusArray;
        closingTimeArray = _closingTimeArray;
        decimals = _decimals;
        goalWeiRaiseIco = _miscConstructorArray[2];
        goalWeiRaisePreIco = _miscConstructorArray[3];
        goalPreIcoBonus = _miscConstructorArray[4];
        innTokenIcoReleaseDate = _miscConstructorArray[5];
        name = _name;
        openingTimeArray = _openingTimeArray;
        rate = _miscConstructorArray[6];
        symbol = _symbol;
        targetAddress = _targetAddress;
        token = _createTokenContract();
    }

    /// @dev fallback function ***DO NOT OVERRIDE*** but overridden as all ETH must be authorized
    function () external payable {
        revert();
        //produceTokensDuringOpenPeriod(msg.sender);
    }

    /// @dev Method to claim release of escrow if relevant
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        escrow.refund(msg.sender);
    }


    /// @dev Serves to close out production after phases and internal production have been completed
    function finish() public onlyController {
        require(!isFinalized);

        if(tokensProducedCommunity >= capTokensCommunityReserve &&
        tokensProducedCompany >= capTokensCompanyReserve &&
        tokensProducedTeam >= capTokensTeam &&
        (stage == IcoStage.Ico &&
        (tokensProducedIco >= capTokensIco ||
        tokensProducedPreIco < goalWeiRaisePreIco))) {  // All internal production has been completed
            _finalize();  // Go ahead and finalize
        } else {
            emit FinishCallFailed(tokensProducedCommunity, tokensProducedCompany, tokensProducedTeam,
                tokensProducedIco, tokensProducedPreIco, stage);
        }
    }

    /// @dev Checks whether funding goal was reached for a given phase
    function goalReached() public view returns (bool) {
        bool isReached = false;

        if(stage == IcoStage.PreIco && weiRaisedPreIco >= goalWeiRaisePreIco ||
        stage == IcoStage.Ico && weiRaisedIco >= goalWeiRaiseIco) {
            isReached = true;
        }

        return isReached;
    }

    /// @dev Checks whether the period in which a phase is open has already elapsed.
    /// @return Whether phase period has elapsed
    function hasClosed() public view returns (bool) {
        return block.timestamp > closingTimeArray[1];  // Solium disable as won't compile (block) - ICO complete
    }

    /// @dev Low-level token production ***DO NOT OVERRIDE*** but overridden to allow for specific usage
    /// @param _innRecipient Address requesting the tokens produced
    /// @param _v ECDSA signature parameter v
    /// @param _r ECDSA signature parameter r
    /// @param _s ECDSA signature parameter s
    function produceTokensDuringOpenPeriod(address _innRecipient, uint8 _v, bytes32 _r, bytes32 _s)
        onlyValidAccess(_v, _r, _s) isOpenPeriod tokenPhaseProductionCapNotExceeded
        recipientNotCapped(_innRecipient) tokenPhaseHardCapNotExceeded public payable {
        require(msg.value > 0);
        weiRaised = weiRaised.plus(msg.value);

        if(stage == IcoStage.PreIco) {
            weiRaisedPreIco = weiRaised.plus(msg.value);
        } else if(stage == IcoStage.Ico) {
            weiRaisedIco = weiRaisedIco.plus(msg.value);
        }

        if((stage == IcoStage.PreIco && weiRaisedPreIco < goalWeiRaisePreIco) ||
            (stage == IcoStage.Ico && weiRaisedIco < goalWeiRaiseIco)) {
            uint256 tenPercent = msg.value / 10;
            _escrowFunds(tenPercent.times(9));  // Escrows ETH funds if goal has not yet been reached
            targetAddress.transfer(tenPercent);
        } else {  // Go ahead and transfer ETH to proper location
            _closeEscrowPhase();
            targetAddress.transfer(msg.value);
        }

        new InnLockup(token, _innRecipient, innTokenIcoReleaseDate);
        emit TokenProduction(msg.sender, _innRecipient, msg.value, innTokensToProduce);
        _postValidateProduction(_innRecipient, msg.value);  // DEV - Has no function yet
    }

    /// @dev Allows for the internal production of tokens, as appropriate
    /// @param purpose Tranche for the production to be run against
    function produceTokensInternal(TokenPurpose purpose, uint256 quantity,
        uint256 innInternalReleaseDate) public onlyController tokenTypeProductionNotExceeded(purpose) {
        new InnLockup(token, targetAddress, innInternalReleaseDate);

        if(purpose == TokenPurpose.Community) {
            tokensProducedCommunity = tokensProducedCommunity.plus(quantity);
        } else if (purpose == TokenPurpose.Company) {
            tokensProducedCompany = tokensProducedCompany.plus(quantity);
        } else if (purpose == TokenPurpose.Team) {
            tokensProducedTeam = tokensProducedTeam.plus(quantity);
        }
    }

    /// @dev Change the current rate; only to be used if ETH/$ drops below $300 during pre-ICO or ICO
    function setCurrentRate(uint256 _rate) public onlyController {
        rate = _rate;
    }

    /// @dev Allow for transition manually of stage from Pre-ICO to ICO
    function setProductionStage(uint value) public onlyController {
        IcoStage _stage;

        if (uint(IcoStage.PreIco) == value) {
            _stage = IcoStage.PreIco;
        } else if (uint(IcoStage.Ico) == value) {
            _stage = IcoStage.Ico;
        }

        stage = _stage;
    }

    /// @dev Calculate pre-ICO bonus for token production
    function _calculateBonus() internal view arraysHaveEqualLength returns (uint256) {
        uint256 arrLen = bonusStartArray.length;

        for(uint8 x = 0; x < arrLen; ++x) {
            if(bonusEndArray[x] > block.timestamp && bonusStartArray[x] <= block.timestamp) {
                return bonusInnPercentArray[x];
            }
        }
    }

    /// @dev Close out an escrow phase as goal has been hit
    function _closeEscrowPhase() internal {
        escrow.close();
    }

    /// @dev Automatically called when this contract deployed
    /// @return TokenBaseInn
    function _createTokenContract() internal returns (TokenBaseInn) {
        return new TokenBaseInn(name, symbol, decimals);
    }

    /// @dev Place produced tokens into escrow pending lockout end
    function _escrowFunds(uint256 amount) internal {
        targetAddress.transfer(amount);
        escrow.deposit.value(amount)(msg.sender);
    }

    /// @dev Must be called after production ends, to do extra work through finalization function
    function _finalize() internal {
        require(!isFinalized);
        require(hasClosed());
        emit Finalized();

        isFinalized = true;
    }

    /// @dev Override to extend the way in which ether is converted to tokens.
    /// @param _weiAmount Value in wei to be converted into tokens
    /// @return Number of tokens that can be produced with the specified _weiAmount
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.times(rate);
    }

    /// @dev Validation of produced tokens. Observe state and use revert statements when valid conditions are not met.
    /// @param _innRecipient Address requesting the tokens produced
    /// @param _weiAmount Value in wei involved in the production
    function _postValidateProduction(address _innRecipient, uint256 _weiAmount) internal {
        emit Produced(_innRecipient, _weiAmount);
    }
}