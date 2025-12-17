// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleVotingNFT} from "../src/SimpleVotingNFT.sol";

contract SimpleVotingNFTTest is Test {
    SimpleVotingNFT public votingNFT;

    address public owner = address(1);
    address public minter = address(2);
    address public user = address(3);
    address public unauthorized = address(4);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        vm.prank(owner);
        votingNFT = new SimpleVotingNFT();
    }

    // ========== DEPLOYMENT TESTS ==========

    /// @notice Vérifie que le contrat NFT est déployé correctement avec le nom, symbole et rôle admin
    function test_Deployment() public view {
        assertEq(votingNFT.name(), "SimpleVotingNFT");
        assertEq(votingNFT.symbol(), "SVN");
        assertTrue(votingNFT.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    // ========== ROLE MANAGEMENT TESTS ==========

    /// @notice Vérifie qu'un admin peut accorder le rôle MINTER à une adresse
    function test_GrantMinterRole() public {
        vm.prank(owner);
        votingNFT.grantMinterRole(minter);
        assertTrue(votingNFT.hasRole(MINTER_ROLE, minter));
    }

    /// @notice Vérifie qu'une adresse non-admin ne peut pas accorder le rôle MINTER
    function test_RevertWhen_NonAdminGrantsMinterRole() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        votingNFT.grantMinterRole(minter);
    }

    /// @notice Vérifie que le déployeur reçoit automatiquement le rôle DEFAULT_ADMIN
    function test_OwnerHasDefaultAdminRole() public view {
        assertTrue(votingNFT.hasRole(DEFAULT_ADMIN_ROLE, owner));
    }

    // ========== MINTING TESTS ==========

    /// @notice Vérifie qu'une adresse avec le rôle MINTER peut minter un NFT à un utilisateur
    function test_MintByMinter() public {
        // Grant minter role
        vm.prank(owner);
        votingNFT.grantMinterRole(minter);

        // Mint NFT
        vm.prank(minter);
        votingNFT.mint(user);

        assertEq(votingNFT.balanceOf(user), 1);
        assertEq(votingNFT.ownerOf(1), user);
    }

    /// @notice Vérifie qu'un minter peut minter plusieurs NFTs à différents utilisateurs avec des IDs séquentiels
    function test_MintMultipleNFTs() public {
        vm.prank(owner);
        votingNFT.grantMinterRole(minter);

        address user2 = address(5);

        vm.startPrank(minter);
        votingNFT.mint(user);
        votingNFT.mint(user2);
        vm.stopPrank();

        assertEq(votingNFT.balanceOf(user), 1);
        assertEq(votingNFT.balanceOf(user2), 1);
        assertEq(votingNFT.ownerOf(1), user);
        assertEq(votingNFT.ownerOf(2), user2);
    }

    /// @notice Vérifie qu'une adresse sans le rôle MINTER ne peut pas minter de NFT
    function test_RevertWhen_NonMinterMints() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        votingNFT.mint(user);
    }

    /// @notice Vérifie qu'on ne peut pas minter un NFT à l'adresse zéro
    function test_RevertWhen_MintToZeroAddress() public {
        vm.prank(owner);
        votingNFT.grantMinterRole(minter);

        vm.prank(minter);
        vm.expectRevert();
        votingNFT.mint(address(0));
    }

    // ========== BALANCE TESTS ==========

    /// @notice Vérifie que la balance d'un utilisateur passe de 0 à 1 après avoir reçu un NFT
    function test_BalanceOfAfterMint() public {
        vm.prank(owner);
        votingNFT.grantMinterRole(minter);

        assertEq(votingNFT.balanceOf(user), 0);

        vm.prank(minter);
        votingNFT.mint(user);

        assertEq(votingNFT.balanceOf(user), 1);
    }

    /// @notice Vérifie qu'un utilisateur peut recevoir plusieurs NFTs et que sa balance augmente en conséquence
    function test_BalanceOfMultipleMints() public {
        vm.prank(owner);
        votingNFT.grantMinterRole(minter);

        vm.startPrank(minter);
        votingNFT.mint(user);
        votingNFT.mint(user);
        votingNFT.mint(user);
        vm.stopPrank();

        assertEq(votingNFT.balanceOf(user), 3);
    }

    // ========== SUPPORTS INTERFACE TESTS ==========

    /// @notice Vérifie que le contrat supporte les interfaces ERC721 et AccessControl
    function test_SupportsInterface() public view {
        // ERC721 interface ID
        assertTrue(votingNFT.supportsInterface(0x80ac58cd));
        // AccessControl interface ID
        assertTrue(votingNFT.supportsInterface(0x7965db0b));
    }
}
