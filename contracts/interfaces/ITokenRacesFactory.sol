// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITokenRacesFactory {
    
    function startRacingToken (string memory name,string memory symbol, uint totalSupply,uint32 id)  external returns(address);
    
    function showCurrentRaceId() external view returns(uint32);
}