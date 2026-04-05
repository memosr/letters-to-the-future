// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {LettersToTheFuture} from "../src/LettersToTheFuture.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        LettersToTheFuture letters = new LettersToTheFuture();
        vm.stopBroadcast();

        console.log("LettersToTheFuture deployed at:", address(letters));
    }
}
