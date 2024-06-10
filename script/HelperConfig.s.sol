// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfiguration {
        uint256 entranceFess;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address linkToken;
        uint256 deployerKey;
    }

    NetworkConfiguration public activeNetworkConfig;
    uint96 private constant BASEFEE = 100000000000000000;
    uint96 private constant GASPRICELINK = 1000000000;
    int256 private constant WEI_PER_UNIT_LINK = 1e18;
    uint256 private constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

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
        view
        returns (NetworkConfiguration memory)
    {
        return
            NetworkConfiguration({
                entranceFess: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 95678359735047877044267886770527297932509304334152594456049795475749140701316,
                callbackGasLimit: 2500000,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getMainnetNetworkConfiguration()
        public
        view
        returns (NetworkConfiguration memory)
    {
        return
            NetworkConfiguration({
                entranceFess: 0.01 ether,
                interval: 30,
                vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
                gasLane: 0x3fd2fec10d06ee8f65e7f2e95f5c56511359ece3f33960ad8a866ae24a8ff10b,
                subscriptionId: 0,
                callbackGasLimit: 2500000,
                linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    function getAndCreateAnvilNetworkConfiguration()
        public
        returns (NetworkConfiguration memory)
    {
        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(
                BASEFEE,
                GASPRICELINK,
                WEI_PER_UNIT_LINK
            );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        return
            NetworkConfiguration({
                entranceFess: 0.01 ether,
                interval: 30,
                vrfCoordinator: address(vrfCoordinatorV2_5Mock),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000000,
                linkToken: address(linkToken),
                deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
            });
    }
}
