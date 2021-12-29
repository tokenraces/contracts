// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// Chainlink
import "./chainlink/VRFConsumerBase.sol";
// Custom
import "./interfaces/ITokenRacesRouter.sol";
import "./interfaces/IRandomNumberGenerator.sol";


contract SpecialRaceRandomNumberGenerator is VRFConsumerBase, IRandomNumberGenerator, Ownable {
    address public tokenRacesRouter;
    bytes32 public keyHash;
    bytes32 public latestRequestId;
    uint64 public randomResult;
    uint256 public fee;
    uint256 latestRaceId;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery.
     * Once the lottery contract is deployed, setLotteryAddress must be called.
     * https://docs.chain.link/docs/vrf-contracts/
     * @param _vrfCoordinator: address of the VRF coordinator
     * @param _linkToken: address of the LINK token
     * @param _fee fee
     * @param _keyHash hash
     */
    constructor(address _vrfCoordinator, address _linkToken,uint256 _fee,bytes32 _keyHash) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        fee=_fee; // _fee * 10 ** 18;
        keyHash=_keyHash;
    }

    /**
     * @notice Request randomness from a user-provided seed
     * @param _seed: seed provided by the Racing Token Router
     */
    function getRandomNumber(uint256 _seed) external override {
        require(msg.sender == tokenRacesRouter, "Only TokenRacesRouter");
        require(keyHash != bytes32(0), "Must have valid key hash");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
        latestRequestId = requestRandomness(keyHash, fee,_seed);
    }

    /**
     * @notice Change the fee
     * @param _fee: new fee (in LINK)
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash: new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice Set the address for the TokenRacesRouter
     * @param _tokenRacesRouter: address of the Token Races Router
     */
    function setRacingTokenRouterAddress(address _tokenRacesRouter) external onlyOwner {
        tokenRacesRouter = _tokenRacesRouter;
    }    

    /**
     * @notice View latest race number
     */
    function viewLatestRaceId() external view override returns (uint256) {
        return latestRaceId;
    }

    /**
     * @notice View random result
     */
    function viewRandomResult() external view override returns (uint64) {
        return randomResult;
    }

    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(latestRequestId == requestId, "Wrong requestId");
         randomResult = uint64(10000000000 + (randomness % 10000000000));
         latestRaceId = ITokenRacesRouter(tokenRacesRouter).viewCurrentRaceId();
    }   
    
}