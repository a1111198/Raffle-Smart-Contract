// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function createSubscriptionConfig() public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        console.log("HelperConfig address:", address(helperConfig));
        (, , address vrfCoordinator, , , , ) = helperConfig
            .activeNetworkConfig();
        console.log("VRFCoordinator address:", vrfCoordinator);
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint256) {
        console.log("Starting broadcast...");
        vm.startBroadcast();

        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        console.log("Subscription Id from VRFCoordinator:", subId);

        vm.stopBroadcast();
        console.log("Stopped broadcast.");
        return subId;
    }

    function run() external returns (uint256) {
        console.log("Running script...");
        uint256 subId = createSubscriptionConfig();
        console.log("Returned Subscription Id:", subId);
        return subId;
    }
}

contract FundSubscription is Script {
    uint96 private constant FUND_AMOUNT = 1 ether;

    function fundSubscriptiononfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint256 subscriptionId,
            ,
            address linkToken
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint256 subcriptionId,
        address linkToken
    ) public {
        console.log("Funding Subscription with subId", subcriptionId);
        console.log("VRF Coordinator is", vrfCoordinator);
        console.log("Link Token is", linkToken);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subcriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subcriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptiononfig();
    }
}

contract AddConsumer is Script {
    function addConsumerConfig(Raffle raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCoordinator,
            ,
            uint256 subscriptionId,
            ,

        ) = helperConfig.activeNetworkConfig();
        addConsumer(vrfCoordinator, subscriptionId, address(raffle));
    }

    function addConsumer(
        address vrfCoordinator,
        uint256 subscriptionId,
        address contractAddress
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            contractAddress
        );
        vm.stopBroadcast();
    }

    function run() external {
        address contractAddress = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        Raffle raffle = Raffle(contractAddress);
        addConsumerConfig(raffle);
    }
}
