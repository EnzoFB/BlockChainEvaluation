// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {SimpleVotingNFT} from "../src/SimpleVotingNFT.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract DeployVotingSystem is Script {
    function run() external returns (SimpleVotingNFT, SimpleVotingSystem) {
        // Récupère la clé privée depuis l'environnement
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Déployer le contrat NFT
        console2.log("Deploying SimpleVotingNFT...");
        SimpleVotingNFT votingNFT = new SimpleVotingNFT();
        console2.log("SimpleVotingNFT deployed at:", address(votingNFT));

        // 2. Déployer le contrat de vote
        console2.log("Deploying SimpleVotingSystem...");
        SimpleVotingSystem votingSystem = new SimpleVotingSystem(address(votingNFT));
        console2.log("SimpleVotingSystem deployed at:", address(votingSystem));

        // 3. Accorder le rôle MINTER au contrat de vote
        console2.log("Granting MINTER_ROLE to VotingSystem...");
        votingNFT.grantMinterRole(address(votingSystem));
        console2.log("MINTER_ROLE granted successfully");

        vm.stopBroadcast();

        // Afficher un résumé
        console2.log("\n=== Deployment Summary ===");
        console2.log("SimpleVotingNFT:", address(votingNFT));
        console2.log("SimpleVotingSystem:", address(votingSystem));
        console2.log("Admin:", msg.sender);
        console2.log("==========================\n");

        return (votingNFT, votingSystem);
    }
}
