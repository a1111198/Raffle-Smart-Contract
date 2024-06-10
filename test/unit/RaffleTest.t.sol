// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployRaffle;

    address PLAYER = makeAddr("player");
    uint256 public STARTING_BALANCE = 10 ether;

    uint256 s_entranceFess;
    uint256 s_interval;
    address s_vrfCoordinator;
    bytes32 s_gasLane;
    uint256 s_subscriptionId;
    uint32 s_callbackGasLimit;
    address s_linkToken;

    function setUp() external {
        deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (
            s_entranceFess,
            s_interval,
            s_vrfCoordinator,
            s_gasLane,
            s_subscriptionId,
            s_callbackGasLimit,
            s_linkToken,

        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    // testing Immutables values.

    function testEntranceFees() external view {
        assert(raffle.getEntranceFees() == s_entranceFess);
    }

    function testRaffleOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testLastTimestamp() external view {
        assert(block.timestamp == raffle.getLastTimeStamp());
    }

    // testing Raffle Entrance:
    //1. minimum balance,
    //2. Sate check
    //3. Success
    //4. event check.

    function testRaffleRevertWhenYouDoNotPayEnogh() external {
        //Arrange
        vm.prank(PLAYER);
        //Expect Revert
        vm.expectRevert(Raffle.Raffle__NotEnoghEthSent.selector);
        //Act
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function testRaffleRecordPlayerWhenEntered() external {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: s_entranceFess}();
        //Asset
        assert(address(PLAYER) == raffle.getPlayer(0));
    }

    function testRaffleEventEmitWhenPlayerEntered() external {
        //Arrange
        vm.prank(PLAYER);
        //Emit Event
        address eventEmmiterAddress = address(raffle);
        vm.expectEmit(true, false, false, false, eventEmmiterAddress);
        emit PlayerEntered(address(PLAYER));
        //Act
        raffle.enterRaffle{value: s_entranceFess}();
    }

    modifier elapseTime() {
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier enterPlayer() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: s_entranceFess}();
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testRevertWhenStateIsCalculating() external enterPlayer {
        //Arrange

        raffle.performUpkeep("");
        //Expect Revert
        vm.expectRevert(Raffle.Raffle__NotAcceptingEntries.selector);
        //Act
        vm.prank(PLAYER);
        raffle.enterRaffle{value: s_entranceFess}();
    }

    // testing checkUpKeep Function
    // 1. time
    //2. state
    //3. balance
    //4. Empty Raffle
    //5. All positive

    function testCheckUpKeepNeededWhenEnoughTimeNotElapsed() external {
        //arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: s_entranceFess}();
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpKeep("");
        // assert
        assert(!upkeepNeeded);
    }

    function testCheckUpKeepNeededWhenRaffleIsOpen() external enterPlayer {
        //Arrange

        raffle.performUpkeep("");
        // Act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("0x0");
        //Assert
        assert(raffle.getIfTimeElapsed());
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepWhenNotHaveEnoughBalance() external elapseTime {
        //Arrange

        // Act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("0x0");
        // Assert
        assert(raffle.getIfTimeElapsed());
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepWhenNoPlayerIsThereInRaffle() external elapseTime {
        //Arrange
        vm.deal(address(raffle), 1 ether);
        // Act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("0x0");
        // Assert
        assert(raffle.getIfTimeElapsed());
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(address(raffle).balance != 0);
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepNeededWhenUpKeepNeeded() external enterPlayer {
        // Arrange
        // Act
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        // assert
        assert(upKeepNeeded);
    }

    // testing PerformUpKeep function
    // 1. needed
    // 2. not Needed

    function testPerformUpKeepWhenUpKeepNeeded() external enterPlayer {
        // Arrange
        // ACT
        raffle.performUpkeep("");
    }

    function testRevertPerformUpKeepWhenUpKeepNotNeeded() external {
        // Arrange
        vm.prank(PLAYER);
        uint256 balance = 0;
        uint256 playersLength = 0;
        uint256 raffleState = 0;
        // Expect Revert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                balance,
                playersLength,
                raffleState
            )
        );
        // ACT
        raffle.performUpkeep("");
    }

    function testPerformUpKeepUpdatesRaffleStateAndRecordRequestId()
        external
        enterPlayer
    {
        //Arrange
        vm.recordLogs();
        //Act
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[0];

        assert(requestId > 0);

        //
    }

    // modifier  to Skip some test Cases because on fork testing that doesn't support.
    modifier skipTest() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    //fullFill Random Words and then test

    function testFullFillRandomNumberRevertCanCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) external enterPlayer skipTest {
        //Arrange
        // Expect Revert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // Act
        VRFCoordinatorV2_5Mock(s_vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    // Full Testing
    function testAfterWinnerPickingCheckForExpectedState()
        external
        enterPlayer
        skipTest
    {
        //Arrange
        uint256 totalPlayers = 5;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i < totalPlayers; i++) {
            address player = address(uint160(i));
            hoax(player, STARTING_BALANCE);
            raffle.enterRaffle{value: s_entranceFess}();
        }
        uint256 winnerPrize = (totalPlayers) * s_entranceFess;
        // Now We have to call FullFillRanodm Number Function
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1];
        uint256 request_Id = uint256(requestId);
        console.log("Request Id after conversion", request_Id);

        uint256 previousTimeStamp = raffle.getLastTimeStamp();
        uint256 contractBalance = address(raffle).balance;
        console.log("Contract balance", contractBalance);
        console.log("Winer Price pool", winnerPrize);
        //Act
        // address emitterAddress= address(raffle);
        // vm.expectEmit(true, false,false, false, emitterAddress);

        VRFCoordinatorV2_5Mock(s_vrfCoordinator).fulfillRandomWords(
            request_Id,
            address(raffle)
        );

        //Assert
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getNumberOfPlayer() == 0);
        assert(raffle.getLastTimeStamp() > previousTimeStamp);
        uint256 winnerBalance = raffle.getRecentWinner().balance;
        uint256 finalWinnerbalance = STARTING_BALANCE +
            winnerPrize -
            s_entranceFess;

        assert(winnerBalance == finalWinnerbalance);
        assert(address(raffle).balance == 0);
    }
}
