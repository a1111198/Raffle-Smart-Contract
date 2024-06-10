// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle raffle, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();

        (
            uint256 entranceFess,
            uint256 interval,
            address vrfCoordinator,
            bytes32 gasLane,
            uint256 subscriptionId,
            uint32 callbackGasLimit,
            address linkToken,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        console.log("VRF", vrfCoordinator);
        if (subscriptionId == 0) {
            // Create our Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );
            // Fund our Subscription

            FundSubscription fundSubscription = new FundSubscription();
            console.log(
                "HERE IN DEPLOY SCRIPT VRF Coordinator",
                vrfCoordinator
            );
            console.log("HERE IN DEPLOY SCRIPT VRF SID", subscriptionId);
            console.log("HERE IN DEPLOY SCRIPT linkToken", linkToken);
            console.log("HERE IN DEPLOY SCRIPT Deeploy key", deployerKey);
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                linkToken,
                deployerKey
            );
        }
        //Deploy Contract
        vm.startBroadcast();
        raffle = new Raffle(
            entranceFess,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();
        // Add consumer:
        AddConsumer addConsumer = new AddConsumer();
        address raffleAddress = address(raffle);
        addConsumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            raffleAddress,
            deployerKey
        );

        return (raffle, helperConfig);
    }
}
