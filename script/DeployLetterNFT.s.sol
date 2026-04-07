// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LetterNFT.sol";

contract DeployLetterNFT is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        vm.startBroadcast(privateKey);
        LetterNFT nft = new LetterNFT(deployer);
        vm.stopBroadcast();

        console.log("LetterNFT deployed at:", address(nft));
        console.log("Owner:", deployer);
    }
}
