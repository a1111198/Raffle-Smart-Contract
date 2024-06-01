// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    event PlayerEntered(address indexed player);
    Raffle raffle;
    HelperConfig helperConfig;
    DeployRaffle deployRaffle;

    address PLAYER = makeAddr("player");
    uint256 public STARTING_BALANCE = 10 ether;

    uint256 s_entranceFess;
    uint256 s_interval;
    address s_vrfCoordinator;
    bytes32 s_gasLane;
    uint64 s_subscriptionId;
    uint32 s_callbackGasLimit;

    function setUp() external {
        deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        (
            s_entranceFess,
            s_interval,
            s_vrfCoordinator,
            s_gasLane,
            s_subscriptionId,
            s_callbackGasLimit
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testEntranceFees() external view {
        assert(raffle.getEntranceFees() == s_entranceFess);
    }

    function testRaffleOpenState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
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

    function testRevertWhenStateIsCalculating() external {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: s_entranceFess}();
        vm.warp(block.timestamp + s_interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //Expect Revert
        vm.expectRevert(Raffle.Raffle__NotAcceptingEntries.selector);
        //Act
        vm.prank(PLAYER);
        raffle.enterRaffle{value: s_entranceFess}();
    }
}
