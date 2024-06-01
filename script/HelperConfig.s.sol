// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfiguration {
        uint256 entranceFess;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }
    // The address of the Chainlink ETH/USD price feed
    NetworkConfiguration public activeNetworkConfig;
    uint96 private constant BASEFEE = 100000000000000000;
    uint96 private constant GASPRICELINK = 1000000000;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetNetworkConfiguration();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaNetworkConfiguration();
        } else {
            activeNetworkConfig = getAndCreateAnvilNetworkConfiguration();
        }
    }

    function getSepoliaNetworkConfiguration()
        public
        pure
        returns (NetworkConfiguration memory)
    {
        return
            NetworkConfiguration({
                entranceFess: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 2500000
            });
    }

    function getMainnetNetworkConfiguration()
        public
        pure
        returns (NetworkConfiguration memory)
    {
        return
            NetworkConfiguration({
                entranceFess: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 2500000
            });
    }

    function getAndCreateAnvilNetworkConfiguration()
        public
        returns (NetworkConfiguration memory)
    {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2Mock vRFCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            BASEFEE,
            GASPRICELINK
        );
        vm.stopBroadcast();
        return
            NetworkConfiguration({
                entranceFess: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vRFCoordinatorV2Mock),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 2500000
            });
    }
}
