// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest race number
     */
    function viewLatestRaceId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint64);
}
