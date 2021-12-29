// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Custom interfaces
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Router01.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IWETH.sol';
import './interfaces/ITokenRacesRouter.sol';
import './interfaces/ITokenRacesFactory.sol';
import './libraries/ConcatStrings.sol';
import './interfaces/IRandomNumberGenerator.sol';

contract SmallestRaceRouter is ReentrancyGuard,Ownable,ITokenRacesRouter {
  
    using SafeMath for uint;
    using ConcatStrings for string;
    mapping(address => uint256) private _balances;
    mapping(uint256 => Race) race;
    mapping(uint32 => mapping(uint32 => RaceTicket)) racePlayerIndex;
    mapping(uint32 => mapping(address => RaceTicket)) racePlayer;
    mapping(uint32 => uint32) raceLastPlayerIndex;
    mapping (uint32 => string) raceAuthKeys;
    mapping(uint32 => uint64[]) winnerRaceTicketNumber;
    uint public minAndMaxParticipationFeeAmount = 0.2 ether; 
    uint256 public platformFee = 10;
    uint32 public totalParticipants = 10;
    string private name="Smallest Race";
    string private symbol="SRC";
    uint256 public raceTokenTotalSupply = 10000000000000000000000000;
    address private currentRaceTokenAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2RouterAddress;
    address public tokenRacesFactory;
    address public wethAddress;
    address private marketingAddress = 0xa76F43736B7ef8de3e34e908522f74f36BED282c;
    address private uniswapV2Pair;
    uint32  currentRaceId;
    uint64 private lastWinnerTicketNumber;
    uint256 public maxLengthRace = 4 hours;
    IERC20 public weth;
    IRandomNumberGenerator public randomGenerator;
    
    constructor(address _randomGeneratorAddress,address _tokenRacesFactory,address _wethAddress,address _uniswapV2RouterAddress) {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        tokenRacesFactory = _tokenRacesFactory;
        wethAddress=_wethAddress;
        weth=IERC20(wethAddress);
        uniswapV2RouterAddress=_uniswapV2RouterAddress;
        currentRaceId=0;        
    }
    
    
    function forcedReboot(uint32 raceId) external onlyOwner() {
        require(race[raceId].status == Status.Close,"You cannot start over before the race is over.");
        require(block.timestamp >= race[raceId].endTime, "The race not over");
        uint32 winnerCount =calculateWinner(raceId);
        require(winnerCount == 0,"There are winners");
        randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(raceId, getSeed()))));
    }
    
    
    function accountBalance() external override view returns(uint) {
        return address(this).balance;
    }
    

    function raceBalance(address raceAddress) external override view returns(uint256) {
        return IERC20(raceAddress).balanceOf(address(this));
    } 


    function setMarketingAddress(address newAddress) external override onlyOwner() {
        emit UpdateMarketingAddress(newAddress, marketingAddress);
        marketingAddress=newAddress;
    }
    
      
    function setMinAndMaxParticipationFee(uint _minAndMaxParticipationFeeAmount) external override onlyOwner() {
        if(currentRaceId != 0) {
            require(race[currentRaceId].status == Status.Claimable,"You cannot change the time until the race is over.");
        } 
        emit MinAndMaxParticipationFee(minAndMaxParticipationFeeAmount,_minAndMaxParticipationFeeAmount);
        minAndMaxParticipationFeeAmount=_minAndMaxParticipationFeeAmount;
    }
    
    
    function setPlatformFee(uint256 _platformFee) external override onlyOwner() {
        require(_platformFee <= 10);
        emit PlatformFeeUpdated(platformFee,_platformFee);
        platformFee=_platformFee;
    }
    
    
    function setMaxLengthRace(uint256 _maxLengthRace) external override onlyOwner() {
        if(currentRaceId != 0) {
            require(race[currentRaceId].status == Status.Claimable,"You cannot change the time until the race is over.");
        }        
        emit UpdateMaxLenghtRace(maxLengthRace,_maxLengthRace);
        maxLengthRace = _maxLengthRace;
    }
    

    function setTotalParticipants(uint32 _totalParticipants) external override onlyOwner() {
        if(currentRaceId != 0) {
            require(race[currentRaceId].status == Status.Claimable,"You cannot change the time until the race is over.");
        }        
        emit UpdateTotalParticipants(totalParticipants, _totalParticipants);
        totalParticipants=_totalParticipants;
    }
    

    function setRaceTokenTotalSupply(uint256 _raceTokenTotalSupply) external override onlyOwner() {
        emit UpdateRaceTokenTotalSupply(raceTokenTotalSupply, _raceTokenTotalSupply);
        raceTokenTotalSupply=_raceTokenTotalSupply;
    }
    

    function calculatePlatformFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(platformFee).div(
            10**2
        );
    } 
    

    function approveRace(address raceTokenAddress) private {
        IERC20(raceTokenAddress).approve(uniswapV2RouterAddress, type(uint).max);
    }
    

    function approveRemoveRace() private {
         uint256 liquidty = IERC20(uniswapV2Pair).balanceOf(address(this));    
         IERC20(uniswapV2Pair).approve(uniswapV2RouterAddress,liquidty);
    }
    
    
    function lastPlayerIndex(uint32 raceId) private view returns(uint32) {
        uint32 last = 0;
        for(uint8 i=0;i<=totalParticipants;i++) {
             if(last < racePlayerIndex[raceId][i].playerIndex) {
               last = racePlayerIndex[raceId][i].playerIndex;
             }
        }
        return last;
    }
    
   
    function startRace(uint32 _raceId,string memory _raceAuthKey) external override onlyOwner()  {
      require(race[currentRaceId].status != Status.Open,"You can't start the race"); 
      require(race[_raceId].status == Status.Pending,"Not time to start race");

      raceAuthKeys[_raceId]=_raceAuthKey;
      currentRaceId=_raceId;
      
       race[_raceId] = Race({
           raceId:_raceId,
           status:Status.Open,
           startTime:0,
           endTime:0,
           participationFeeAmountEther:minAndMaxParticipationFeeAmount,
           winnerNumber:[uint64(0), uint64(0), uint64(0), uint64(0), uint64(0), uint64(0), uint64(0),uint64(0),uint64(0),uint64(0)]
       });
       raceLastPlayerIndex[_raceId]=0;
       racePlayerIndex[_raceId][1] = RaceTicket({
            raceTicketNumber: [uint64(0), uint64(0), uint64(0), uint64(0), uint64(0), uint64(0), uint64(0),uint64(0),uint64(0),uint64(0)],
            raceId:_raceId,
            player:address(0),
            countWinnersNumber:0,
            playerIndex:1,
            winner:false
        }); 
    }
    
    function openTrade() external onlyOwner() {
        require(race[currentRaceId].status == Status.Open,"Not time to open trade");
        require(lastPlayerIndex(currentRaceId) == totalParticipants,"Not all players joined in race");
         race[currentRaceId].startTime=block.timestamp;
         race[currentRaceId].endTime=block.timestamp+maxLengthRace;    
         currentRaceTokenAddress = ITokenRacesFactory(tokenRacesFactory).startRacingToken(
           name.concat(Strings.toString(currentRaceId)),
           symbol.concat(Strings.toString(currentRaceId)),
           raceTokenTotalSupply,
           currentRaceId);
           
        approveRace(currentRaceTokenAddress);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(currentRaceTokenAddress), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(currentRaceTokenAddress),
            IERC20(currentRaceTokenAddress).balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );       
    }
    
    function calculateFinalNumber(uint32 _raceId) private {
            uint64 finalNumber = randomGenerator.viewRandomResult();            
            lastWinnerTicketNumber = finalNumber;            
            uint8 count=0;
            while(finalNumber>0 && count<10) {
                 winnerRaceTicketNumber[_raceId].push(finalNumber % 10);
                 finalNumber = finalNumber / 10;
                 count++;
            }            
    }
    
    function finishRace(uint32 raceId) external override onlyOwner() nonReentrant {
         require(race[raceId].status == Status.Open, "The race not started");
         require(block.timestamp >= race[raceId].endTime, "The race not over");
         require(currentRaceId == raceId, "You can't finish this race");
         approveRemoveRace();
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);     
        _uniswapV2Router.removeLiquidity(            
            address(currentRaceTokenAddress),
            address(wethAddress),
            IERC20(uniswapV2Pair).balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );        
        IWETH(wethAddress).withdraw(weth.balanceOf(address(this))); 
        uint256 tFee = calculatePlatformFee(address(this).balance);
        uint256 tTransferAmount = address(this).balance.sub(tFee);            
        uint256 amount = address(this).balance.sub(tTransferAmount);  
        payable(address(marketingAddress)).transfer(amount / 2);
        payable(address(owner())).transfer(amount / 2);
        randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(raceId, getSeed()))));
        race[raceId].status=Status.Close;
    }
    
    function calculateWinnerNumbers(uint32 _raceId,uint64[10] memory numbers) private view returns (uint8) {
        uint8 times = 0;
        for(uint8 i= 0; i < numbers.length; i++) 
        {
            if(numbers[i] == winnerRaceTicketNumber[_raceId][i]) {
                times++;
            }
        }
        return times;
    } 
    function calculateWinner(uint32 raceId) private returns(uint32) {
      uint32 store_var = 0;
      uint32 winnerCount=0;
      for(uint8 i=0; i<= totalParticipants;i++) {
          if(racePlayerIndex[raceId][i].raceId == raceId) {
              
             racePlayerIndex[raceId][i].countWinnersNumber = calculateWinnerNumbers(raceId,racePlayerIndex[raceId][i].raceTicketNumber);
               if(store_var < racePlayerIndex[raceId][i].countWinnersNumber) {
               store_var = racePlayerIndex[raceId][i].countWinnersNumber;
             }
          }
      }
      
      for(uint8 j=0; j<= totalParticipants; j++) {
          if(racePlayerIndex[raceId][j].raceId == raceId) 
            if(store_var == racePlayerIndex[raceId][j].countWinnersNumber)
            {
                winnerCount++;
                racePlayerIndex[raceId][j].winner=true;
                racePlayer[raceId][racePlayerIndex[raceId][j].player].winner=true;
            }
      }     
      return winnerCount;
    } 
    
    function drawClaimable(uint32 _raceId) external override onlyOwner() nonReentrant {
        require(race[_raceId].status == Status.Close, "The race not closed"); 
        calculateFinalNumber(_raceId);
        uint32 winnerCount =calculateWinner(_raceId);
        require(winnerCount !=0,"You need to do a forced reboot");
        uint256 tTransferAmount=0;
        if(winnerCount == 1)
         tTransferAmount = address(this).balance;
        else
         tTransferAmount = address(this).balance.div(winnerCount); 
         
         for (uint8 i = 0; i <= totalParticipants; i++) {
             if(racePlayerIndex[_raceId][i].winner == true)
                payable(address(racePlayerIndex[_raceId][i].player)).transfer(tTransferAmount);
        }
        race[_raceId].status = Status.Claimable;
    }
    
    function joinRace(uint32 _raceId,string calldata _raceAuthKey,uint64[10] calldata _raceTicket) external override payable nonReentrant {
        require(keccak256(abi.encodePacked(_raceAuthKey)) == keccak256(abi.encodePacked(raceAuthKeys[_raceId])), "Wrong auth key");
        require(race[_raceId].status == Status.Open, "The race not started");
        require(racePlayer[_raceId][msg.sender].player != msg.sender, "You can't join again same race");
        require(raceLastPlayerIndex[_raceId] < totalParticipants,"No more players can join");
        require(msg.value == minAndMaxParticipationFeeAmount,"Not enough fee");
        require(_raceTicket.length != 9, "No race ticket specified");   
        raceLastPlayerIndex[_raceId]++;
        
        racePlayerIndex[_raceId][raceLastPlayerIndex[_raceId]] = RaceTicket({
            raceTicketNumber:_raceTicket,
            raceId:_raceId,
            player:msg.sender,
            countWinnersNumber:0,
            playerIndex:raceLastPlayerIndex[_raceId],
            winner:false
        }); 
        racePlayer[_raceId][msg.sender] =racePlayerIndex[_raceId][raceLastPlayerIndex[_raceId]];        
    }
    
    function setUniswapV2Router(address newAddress) external override onlyOwner() {
        if(currentRaceId != 0) {
            require(race[currentRaceId].status == Status.Claimable,"The race not closed");
        }      
        emit UpdateUniswapV2Router(newAddress, uniswapV2RouterAddress);
        uniswapV2RouterAddress=newAddress;
    }
    
    function setTokenRacesFactoryAddress(address newFactoryAddress) external override onlyOwner() {
        if(currentRaceId != 0) {
            require(race[currentRaceId].status == Status.Claimable,"The race not finished");
        }        
        emit UpdateTokenRacesFactoryAddress(newFactoryAddress, tokenRacesFactory);
        tokenRacesFactory=newFactoryAddress;
    }
    
    function setRandomNumberGeneratorAddress(address newGeneratorAddress) external override onlyOwner() {
        if(currentRaceId != 0) {
            require(race[currentRaceId].status == Status.Claimable,"The race not finished");
        }        
        randomGenerator = IRandomNumberGenerator(newGeneratorAddress);
    }
    
    function viewCurrentRaceId() external override view returns(uint32) {
        return currentRaceId;
    }

    function getSeed() internal virtual view returns (uint256 seed) {
        return uint256(blockhash(block.number - 1));
    }

    function getLastWinnerTicketNumber() public view returns(uint64) {
        return lastWinnerTicketNumber;
    }
          
    function getJoinedPlayer(uint32 _raceId,address player) public view returns(bool) {
        if(racePlayer[_raceId][player].player == player)
            return true;
        else 
            return false;
    }
    
    function getWinnerPlayer(uint32 _raceId,address player) public view returns(bool) {
       return racePlayer[_raceId][player].winner;
    }
    
    function getCurrentRaceTokenAddress() public view returns(address) {
        return currentRaceTokenAddress;
    }

    function getRaceStatus(uint32 raceId) public view returns(Status) {
        return race[raceId].status;
    }
    
    function getRaceEndTime(uint32 _raceId) public view returns(uint256) {
        return race[_raceId].startTime - race[_raceId].endTime;
    }

    function getMinAndMaxParticipationFeeAmount() public view returns(uint256) {
        return minAndMaxParticipationFeeAmount;  
    }

    fallback() external payable {}
    receive() external payable {}

}
