// Pragma statements

// Import statements

// Events

// Errors

// Interfaces

// Libraries

// Contracts

// Type declarations

// State variables

// Events

// Errors

// Modifiers

// Functions

// constructor

// receive function (if exists)

// fallback function (if exists)

// external

// public

// internal

// private

// Within a grouping, place the view and pure functions last.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/// @title This is a Contract for Fair Lottery system with varifyable Random winnner.
/// @author Akash Bansal
/// @notice Implements Chainlinks VRF for Random Number generation.

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoghEthSent();
    error Raffle__TransferFailed();
    error Raffle__NotAcceptingEntries();
    error Raffle__UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 players,
        uint256 raffleState
    );
    /*Type Declaration*/

    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    /* State Variables*/

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entraceFee;
    // @dev this is Duration in second for this Raffle to be active.
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**Events*/

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFess,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subcriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entraceFee = entranceFess;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        i_gasLane = gasLane;
        i_subscriptionId = subcriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entraceFee) {
            revert Raffle__NotEnoghEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotAcceptingEntries();
        }
        s_players.push(payable(msg.sender));

        emit PlayerEntered(msg.sender);
    }

    //1. get a Random Number less than array length;
    //2. Pick a player from that Index
    //3. Call this Function automatically

    //@dev this is a function that chainLink automation nodes Call:
    // it checks for the follwing:
    // 1. Time greater than interval time must be passed.
    // 2. Raffle must be in open State
    // 3. contract must have an ETH balance to transfer;
    // 4. there must be players in the Raffle;

    function checkUpKeep(
        bytes memory /*checkData*/
    ) public view returns (bool updateNeeded, bytes memory /* performData */) {
        bool timeElapsed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleOpenState = s_raffleState == RaffleState.OPEN;
        bool nonZeroBalance = address(this).balance != 0;
        bool nonEmptyRaffle = s_players.length != 0;
        updateNeeded = (timeElapsed &&
            raffleOpenState &&
            nonZeroBalance &&
            nonEmptyRaffle);
        return (updateNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpKeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING_WINNER;
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        //Checks (Check for If -> Error)

        // Effects (changes that our contract would perform)
        uint256 randomWinnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[randomWinnerIndex];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);
        // Interactions with other Contracts or External Interactions
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /* Gatters */

    function getEntranceFees() external view returns (uint256) {
        return i_entraceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 playerIndex) external view returns (address) {
        return s_players[playerIndex];
    }
}
