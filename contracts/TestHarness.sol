pragma solidity ^0.4.24;

contract TestHarness {
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
    
    event TestResults(uint256 testEvent);
    
    constructor(uint256[] _bonusStartArray, uint256[] _bonusEndArray, uint8[] _bonusInnPercentArray,
        uint32[] _capConstructorArray, uint32[] _closeGoalBonusArray, uint256[] _closingTimeArray,
        uint8 _decimals, uint256[] _miscConstructorArray, string _name, uint256[] _openingTimeArray,
        string _symbol, address _targetAddress) public {
        difference = now - testTimeArray[0];
        phalanx = 8;
        emit TestResults(difference);
        dodger = 555;
    }
    
    function something() public {
        difference = 2;
    }
}
