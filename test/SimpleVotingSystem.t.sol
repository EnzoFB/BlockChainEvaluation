// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
import {SimpleVotingNFT} from "../src/SimpleVotingNFT.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;
    SimpleVotingNFT public votingNFT;

    address public admin = address(1);
    address public founder = address(2);
    address public voter1 = address(3);
    address public voter2 = address(4);
    address public unauthorized = address(5);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    function setUp() public {
        // Deploy NFT contract
        vm.prank(admin);
        votingNFT = new SimpleVotingNFT();

        // Deploy voting system
        vm.prank(admin);
        votingSystem = new SimpleVotingSystem(address(votingNFT));

        // Grant minter role to voting system
        vm.prank(admin);
        votingNFT.grantMinterRole(address(votingSystem));
    }

    // ========== DEPLOYMENT TESTS ==========

    /// @notice Vérifie que le système de vote est déployé correctement avec le rôle admin et le workflow initialisé
    function test_Deployment() public view {
        assertTrue(votingSystem.hasRole(ADMIN_ROLE, admin));
        assertEq(uint256(votingSystem.workflowStatus()), uint256(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES));
        assertEq(address(votingSystem.votingNFT()), address(votingNFT));
    }

    // ========== ROLE MANAGEMENT TESTS ==========

    /// @notice Vérifie qu'un admin peut accorder le rôle FOUNDER à une adresse
    function test_GrantFounderRole() public {
        vm.prank(admin);
        votingSystem.grantFounder(founder);
        assertTrue(votingSystem.hasRole(FOUNDER_ROLE, founder));
    }

    /// @notice Vérifie qu'une adresse non-admin ne peut pas accorder le rôle FOUNDER
    function test_RevertWhen_NonAdminGrantsFounderRole() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        votingSystem.grantFounder(founder);
    }

    // ========== WORKFLOW TESTS ==========

    /// @notice Vérifie qu'un admin peut changer le statut du workflow
    function test_SetWorkflowStatus() public {
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        assertEq(uint256(votingSystem.workflowStatus()), uint256(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES));
    }

    /// @notice Vérifie que passer au statut VOTE enregistre le timestamp pour le délai de 1 heure
    function test_SetWorkflowStatusToVote_SetsTimestamp() public {
        vm.warp(1000); // Set timestamp

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

        assertEq(votingSystem.voteStartSetAt(), 1000);
    }

    /// @notice Vérifie qu'une adresse non-admin ne peut pas changer le statut du workflow
    function test_RevertWhen_NonAdminSetsWorkflowStatus() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    }

    // ========== CANDIDATE REGISTRATION TESTS ==========

    /// @notice Vérifie qu'un admin peut ajouter un candidat avec un nom, un ID et 0 votes initiaux
    function test_AddCandidate() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        assertEq(votingSystem.getCandidatesCount(), 1);

        SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
        assertEq(candidate.id, 1);
        assertEq(candidate.name, "Alice");
        assertEq(candidate.voteCount, 0);
    }

    /// @notice Vérifie qu'un admin peut enregistrer plusieurs candidats avec des IDs séquentiels
    function test_AddMultipleCandidates() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");
        vm.stopPrank();

        assertEq(votingSystem.getCandidatesCount(), 3);
    }

    /// @notice Vérifie qu'une adresse non-admin ne peut pas enregistrer de candidat
    function test_RevertWhen_NonAdminAddsCandidate() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        votingSystem.addCandidate("Alice");
    }

    /// @notice Vérifie qu'on ne peut pas enregistrer un candidat avec un nom vide
    function test_RevertWhen_AddCandidateWithEmptyName() public {
        vm.prank(admin);
        vm.expectRevert(SimpleVotingSystem.EmptyCandidateName.selector);
        votingSystem.addCandidate("");
    }

    /// @notice Vérifie qu'on ne peut pas enregistrer de candidat en dehors de la phase REGISTER_CANDIDATES
    function test_RevertWhen_AddCandidateInWrongPhase() public {
        // Change phase to VOTE
        vm.startPrank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVotingSystem.WrongPhase.selector,
                SimpleVotingSystem.WorkflowStatus.VOTE,
                SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES
            )
        );
        votingSystem.addCandidate("Alice");
        vm.stopPrank();
    }

    // ========== VOTING TESTS ==========

    /// @notice Vérifie qu'un utilisateur peut voter pour un candidat après le délai de 1 heure et reçoit un NFT
    function test_Vote() public {
        // Setup: Add candidate and set to VOTE phase
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        // Wait 1 hour
        vm.warp(block.timestamp + 1 hours);

        // Vote
        vm.prank(voter1);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 1);
        assertEq(votingNFT.balanceOf(voter1), 1);
    }

    /// @notice Vérifie que plusieurs utilisateurs peuvent voter et que les votes sont correctement comptés
    function test_VoteMultipleVoters() public {
        // Setup
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        // Multiple votes
        vm.prank(voter1);
        votingSystem.vote(1);

        vm.prank(voter2);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 2);
        assertEq(votingSystem.getTotalVotes(2), 0);
    }

    /// @notice Vérifie qu'on ne peut pas voter en dehors de la phase VOTE
    function test_RevertWhen_VoteInWrongPhase() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        // Still in REGISTER_CANDIDATES phase
        vm.prank(voter1);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVotingSystem.WrongPhase.selector,
                SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES,
                SimpleVotingSystem.WorkflowStatus.VOTE
            )
        );
        votingSystem.vote(1);
    }

    /// @notice Vérifie qu'on ne peut pas voter avant le délai de 1 heure après l'ouverture du vote
    function test_RevertWhen_VoteBeforeOneHour() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        // Try to vote immediately
        vm.prank(voter1);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVotingSystem.VotingNotOpenYet.selector, block.timestamp, block.timestamp + 1 hours
            )
        );
        votingSystem.vote(1);
    }

    /// @notice Vérifie qu'un utilisateur possédant déjà un NFT de vote ne peut pas voter à nouveau
    function test_RevertWhen_VoteWithNFT() public {
        // Setup
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        // First vote
        vm.prank(voter1);
        votingSystem.vote(1);

        // Try to vote again
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSelector(SimpleVotingSystem.AlreadyVoted.selector, voter1));
        votingSystem.vote(1);
    }

    /// @notice Vérifie qu'on ne peut pas voter pour un ID de candidat invalide ou inexistant
    function test_RevertWhen_VoteForInvalidCandidate() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSelector(SimpleVotingSystem.InvalidCandidateId.selector, 999));
        votingSystem.vote(999);
    }

    // ========== FUNDING TESTS ==========

    /// @notice Vérifie qu'un founder peut envoyer des fonds à un candidat
    function test_FundCandidate() public {
        // Grant founder role
        vm.prank(admin);
        votingSystem.grantFounder(founder);

        // Add candidate
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        // Move to FOUND_CANDIDATES phase
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        // Fund candidate
        vm.deal(founder, 10 ether);
        vm.prank(founder);
        votingSystem.fundCandidate{value: 5 ether}(1);

        assertEq(votingSystem.candidateFunds(1), 5 ether);
    }

    /// @notice Vérifie qu'un founder peut envoyer des fonds plusieurs fois et qu'ils s'accumulent
    function test_FundCandidateMultipleTimes() public {
        vm.prank(admin);
        votingSystem.grantFounder(founder);

        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.deal(founder, 10 ether);
        vm.startPrank(founder);
        votingSystem.fundCandidate{value: 2 ether}(1);
        votingSystem.fundCandidate{value: 3 ether}(1);
        vm.stopPrank();

        assertEq(votingSystem.candidateFunds(1), 5 ether);
    }

    /// @notice Vérifie qu'une adresse sans le rôle FOUNDER ne peut pas financer un candidat
    function test_RevertWhen_NonFounderFundsCandidate() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.deal(unauthorized, 10 ether);
        vm.prank(unauthorized);
        vm.expectRevert();
        votingSystem.fundCandidate{value: 5 ether}(1);
    }

    /// @notice Vérifie qu'on ne peut pas financer un candidat en dehors de la phase FOUND_CANDIDATES
    function test_RevertWhen_FundCandidateInWrongPhase() public {
        vm.prank(admin);
        votingSystem.grantFounder(founder);

        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        // Still in REGISTER_CANDIDATES phase
        vm.deal(founder, 10 ether);
        vm.prank(founder);
        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVotingSystem.WrongPhase.selector,
                SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES,
                SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES
            )
        );
        votingSystem.fundCandidate{value: 5 ether}(1);
    }

    /// @notice Vérifie qu'on ne peut pas financer un candidat avec un ID invalide
    function test_RevertWhen_FundInvalidCandidate() public {
        vm.startPrank(admin);
        votingSystem.grantFounder(founder);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        vm.stopPrank();

        vm.deal(founder, 10 ether);
        vm.prank(founder);
        vm.expectRevert(abi.encodeWithSelector(SimpleVotingSystem.InvalidCandidateId.selector, 999));
        votingSystem.fundCandidate{value: 5 ether}(999);
    }

    /// @notice Vérifie qu'on ne peut pas financer avec 0 ETH
    function test_RevertWhen_FundWithZeroAmount() public {
        vm.startPrank(admin);
        votingSystem.grantFounder(founder);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        vm.stopPrank();

        vm.prank(founder);
        vm.expectRevert(SimpleVotingSystem.ZeroAmount.selector);
        votingSystem.fundCandidate{value: 0}(1);
    }

    // ========== WINNER TESTS ==========

    /// @notice Vérifie que la fonction getWinner retourne le candidat avec le plus de votes en phase COMPLETED
    function test_GetWinner() public {
        // Setup candidates and votes
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        // Cast votes
        vm.prank(voter1);
        votingSystem.vote(2); // Bob

        vm.prank(voter2);
        votingSystem.vote(2); // Bob

        address voter3 = address(6);
        vm.prank(voter3);
        votingSystem.vote(1); // Alice

        // Set to COMPLETED
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        // Get winner
        (uint256 winnerId, string memory winnerName, uint256 winnerVoteCount) = votingSystem.getWinner();

        assertEq(winnerId, 2);
        assertEq(winnerName, "Bob");
        assertEq(winnerVoteCount, 2);
    }

    /// @notice Vérifie qu'on ne peut pas récupérer le vainqueur en dehors de la phase COMPLETED
    function test_RevertWhen_GetWinnerInWrongPhase() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        vm.expectRevert(
            abi.encodeWithSelector(
                SimpleVotingSystem.WrongPhase.selector,
                SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES,
                SimpleVotingSystem.WorkflowStatus.COMPLETED
            )
        );
        votingSystem.getWinner();
    }

    /// @notice Vérifie qu'on ne peut pas récupérer le vainqueur s'il n'y a aucun candidat enregistré
    function test_RevertWhen_GetWinnerWithNoCandidates() public {
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        vm.expectRevert(SimpleVotingSystem.NoCandidatesRegistered.selector);
        votingSystem.getWinner();
    }

    // ========== GETTER TESTS ==========

    /// @notice Vérifie que getTotalVotes retourne le nombre correct de votes pour un candidat
    function test_GetTotalVotes() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(voter1);
        votingSystem.vote(1);

        assertEq(votingSystem.getTotalVotes(1), 1);
    }

    /// @notice Vérifie que getCandidate retourne les informations complètes d'un candidat
    function test_GetCandidate() public {
        vm.prank(admin);
        votingSystem.addCandidate("Alice");

        SimpleVotingSystem.Candidate memory candidate = votingSystem.getCandidate(1);
        assertEq(candidate.id, 1);
        assertEq(candidate.name, "Alice");
        assertEq(candidate.voteCount, 0);
    }

    /// @notice Vérifie qu'on ne peut pas récupérer un candidat avec un ID invalide
    function test_RevertWhen_GetInvalidCandidate() public {
        vm.expectRevert(abi.encodeWithSelector(SimpleVotingSystem.InvalidCandidateId.selector, 1));
        votingSystem.getCandidate(1);
    }

    /// @notice Vérifie que getAllCandidates retourne tous les candidats enregistrés
    function test_GetAllCandidates() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");
        vm.stopPrank();

        SimpleVotingSystem.Candidate[] memory allCandidates = votingSystem.getAllCandidates();

        assertEq(allCandidates.length, 3);
        assertEq(allCandidates[0].name, "Alice");
        assertEq(allCandidates[1].name, "Bob");
        assertEq(allCandidates[2].name, "Charlie");
    }

    /// @notice Vérifie que getAllCandidates retourne un tableau vide si aucun candidat
    function test_GetAllCandidates_Empty() public view {
        SimpleVotingSystem.Candidate[] memory allCandidates = votingSystem.getAllCandidates();
        assertEq(allCandidates.length, 0);
    }

    // ========== INTEGRATION TESTS ==========

    /// @notice Vérifie que l'événement CandidateAdded est émis lors de l'ajout d'un candidat
    function test_Event_CandidateAdded() public {
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit SimpleVotingSystem.CandidateAdded(1, "Alice");
        votingSystem.addCandidate("Alice");
    }

    /// @notice Vérifie que l'événement Voted est émis lors d'un vote
    function test_Event_Voted() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        vm.prank(voter1);
        vm.expectEmit(true, true, false, false);
        emit SimpleVotingSystem.Voted(voter1, 1);
        votingSystem.vote(1);
    }

    /// @notice Vérifie que l'événement WorkflowStatusChanged est émis
    function test_Event_WorkflowStatusChanged() public {
        vm.prank(admin);
        vm.expectEmit(false, false, false, true);
        emit SimpleVotingSystem.WorkflowStatusChanged(
            SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES, SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES
        );
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
    }

    /// @notice Vérifie que l'événement CandidateFunded est émis
    function test_Event_CandidateFunded() public {
        vm.startPrank(admin);
        votingSystem.grantFounder(founder);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        vm.stopPrank();

        vm.deal(founder, 10 ether);
        vm.prank(founder);
        vm.expectEmit(true, false, true, true);
        emit SimpleVotingSystem.CandidateFunded(1, 5 ether, founder);
        votingSystem.fundCandidate{value: 5 ether}(1);
    }

    // ========== INTEGRATION TESTS ==========

    /// @notice Test d'intégration complet : enregistrement, financement, vote et désignation du vainqueur
    function test_FullVotingWorkflow() public {
        // 1. Register candidates
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");

        // 2. Move to FOUND_CANDIDATES
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        // 3. Grant founder and fund candidates
        votingSystem.grantFounder(founder);
        vm.stopPrank();

        vm.deal(founder, 30 ether);
        vm.startPrank(founder);
        votingSystem.fundCandidate{value: 10 ether}(1);
        votingSystem.fundCandidate{value: 10 ether}(2);
        votingSystem.fundCandidate{value: 10 ether}(3);
        vm.stopPrank();

        // 4. Move to VOTE
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

        vm.warp(block.timestamp + 1 hours);

        // 5. Vote
        vm.prank(voter1);
        votingSystem.vote(2); // Bob

        vm.prank(voter2);
        votingSystem.vote(2); // Bob

        address voter3 = address(6);
        vm.prank(voter3);
        votingSystem.vote(1); // Alice

        // 6. Complete voting
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        // 7. Get winner
        (uint256 winnerId, string memory winnerName, uint256 winnerVoteCount) = votingSystem.getWinner();

        assertEq(winnerId, 2);
        assertEq(winnerName, "Bob");
        assertEq(winnerVoteCount, 2);

        // Verify NFTs were minted
        assertEq(votingNFT.balanceOf(voter1), 1);
        assertEq(votingNFT.balanceOf(voter2), 1);
        assertEq(votingNFT.balanceOf(voter3), 1);

        // Verify funds
        assertEq(votingSystem.candidateFunds(1), 10 ether);
        assertEq(votingSystem.candidateFunds(2), 10 ether);
        assertEq(votingSystem.candidateFunds(3), 10 ether);
    }
}
