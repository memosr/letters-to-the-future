// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LettersToTheFutureV2} from "../src/LettersToTheFutureV2.sol";

contract DeployV2 is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        LettersToTheFutureV2 letters = new LettersToTheFutureV2();
        vm.stopBroadcast();

        console.log("LettersToTheFutureV2 deployed at:", address(letters));
    }
}
