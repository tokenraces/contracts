// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface ITokenRacesRouter {
    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }
    struct Race {  
        uint32 raceId;
        Status status;        
        uint256 startTime;
        uint256 endTime;
        uint participationFeeAmountEther;
        uint64[10] winnerNumber;                
    }
    
    struct RaceTicket {
        uint64[10] raceTicketNumber;
        address player;
        uint32 raceId;
        uint32 countWinnersNumber;
        uint32 playerIndex;
        bool winner;
    }
  
    function accountBalance() external view returns(uint);    

    function raceBalance(address raceTokenAddress) external view returns(uint256);    

    function setMinAndMaxParticipationFee(uint _minAndMaxParticipationFeeAmount) external;

    function setPlatformFee(uint256 _platformFee) external;
    
    function setMaxLengthRace(uint256 _maxLenght) external;

    function setTotalParticipants(uint32 _totalParticipants) external;

    function setRaceTokenTotalSupply(uint256 _raceTokenTotalSupply) external;

    function startRace(uint32 _raceId,string calldata _raceAuthKey) external;
    
    function finishRace(uint32 raceId) external;
    /**
     * @notice Buy race tickets for the current race
     * @param _raceId: raceId
     * @param _raceTicket:_raceTicket
     * @dev Callable by users
     */
    function joinRace(uint32 _raceId,string calldata _raceAuthKey,uint64[10] calldata _raceTicket) external payable;
    
    function drawClaimable(uint32 _raceId) external;

    function setMarketingAddress(address newAddress) external;

    function setUniswapV2Router(address newAddress) external;

    function setTokenRacesFactoryAddress(address newFactoryAddress) external;
    
    function setRandomNumberGeneratorAddress(address newGeneratorAddress) external;
    
    function viewCurrentRaceId () external view returns(uint32);
    
    event MinAndMaxParticipationFee(uint oldAmount, uint newAmount);

    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);  
    
    event UpdateMaxLenghtRace(uint256 oldLenght, uint256 newLenght);

    event UpdateTotalParticipants(uint32 oldTotalParticipants,uint32 newTotalParticipants);

    event UpdateRaceTokenTotalSupply(uint256 oldRaceTokenTotalSupply,uint256 newRaceTokenTotalSupply);

    event UpdateMarketingAddress(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);    

    event UpdateTokenRacesFactoryAddress(address indexed newAddress, address indexed oldAddress);
  
}