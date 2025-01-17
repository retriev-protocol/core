// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../contracts/Retriev.sol";

contract RetrievTest is Test {
    Retriev retriev;

    function setUp() public {
        retriev = new Retriev(address(this));
    }

    function testAddSameProviderTwice() public {
        address provider = vm.addr(5);
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );

        // expect an error
        vm.expectRevert("Provider already exists");
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );
        
        // cleanup
        retriev.removeProvider(provider);
    }

    // SETUP NETWORK
    function testAddProvider() public {
        address provider = vm.addr(5);
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );
        assertEq(
            retriev.isProvider(provider),
            true
        );
    }

    function testAddReferees() public {
        address referee1 = vm.addr(6);
        address referee2 = vm.addr(7);
        address referee3 = vm.addr(8);
        retriev.setRefereeStatus(
            referee1,
            true,
            "http://localhost:9000"
        );
        retriev.setRefereeStatus(
            referee2,
            true,
            "http://localhost:9001"
        );
        retriev.setRefereeStatus(
            referee3,
            true,
            "http://localhost:9002"
        );
    }
    
    // This is not needed now since the fix was implemented
    // function testAddDuplicateReferees() public {
    //     address referee1 = vm.addr(6);
    //     retriev.setRefereeStatus(
    //         referee1,
    //         true,
    //         "http://localhost:9000"
    //     );
    //     vm.expectRevert("Duplicate referees are not permitted");
    //     retriev.setRefereeStatus(
    //         referee1,
    //         true,
    //         "http://localhost:9001"
    //     );
    // }

    // function testRefereeSafeDelete() public {
    //     address referee1 = vm.addr(6);
    //     retriev.setRefereeStatus(
    //         referee1,
    //         true,
    //         "http://localhost:9000"
    //     );
    //     retriev.setRefereeStatus(
    //         referee1,
    //         false,
    //         "http://localhost:9001"
    //     );
    //     vm.expectRevert("Duplicate referees are not permitted");
    //     retriev.setRefereeStatus(
    //         referee1,
    //         true,
    //         "http://localhost:9001"
    //     );
       
    // }

    // CREATE DEAL PROPOSAL
    function testCreateDealProposal() public {
        address provider = vm.addr(5);
        address client = vm.addr(2);
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );
        assertEq(
            retriev.isProvider(provider),
            true
        );
        // Be sure contract is not protected
        retriev.tuneProtocolVariables(2, address(0), false);
        assertEq(
            retriev.contract_protected(),
            false
        );
        uint256 duration = retriev.min_duration();
        uint256 collateral = 1 wei;
        address[] memory providers = new address[](1);
        providers[0] = provider;
        // Defining appeal addresses
        address[] memory appeal_addresses = new address[](1);
        appeal_addresses[0] = client;
        retriev.createDealProposal{value: 1 wei}(
            "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            duration,
            collateral,
            providers,
            appeal_addresses
        );
    }

    // CREATE AND ACCEPT DEAL PROPOSAL
    function testCreateDealProposalAndAccept() public {
        // Deriving new provider from vm.addr function
        address client = vm.addr(2);
        address provider = vm.addr(5);
        // Funding client's address
        vm.deal(client, 100 ether);
        vm.deal(provider, 100 ether);
        // Be sure contract is not protected
        retriev.tuneProtocolVariables(2, address(0), false);
        assertEq(
            retriev.contract_protected(),
            false
        );
        // Setting provider
        retriev.setProviderStatus(provider, true, "http://localhost:8000");
        assertEq(retriev.isProvider(provider), true);
        uint256 duration = retriev.min_duration();
        // Defining deal
        uint256 collateral = 1 wei;
        address[] memory providers = new address[](1);
        providers[0] = provider;
        // Defining appeal addresses
        address[] memory appeal_addresses = new address[](1);
        appeal_addresses[0] = client;
        // Start making calls with client's key
        vm.startPrank(client);
        retriev.createDealProposal{value: 1 wei}(
            "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            duration,
            collateral,
            providers,
            appeal_addresses
        );
        vm.stopPrank();
        // Start making calls with provider's key
        vm.startPrank(provider);
        // Deposit to contract
        retriev.depositToVault{value: 1 ether}();
        // Finally accept the deal
        retriev.acceptDealProposal(1);
        emit log_uint(retriev.balanceOf(provider));
    }

    // CREATE DEAL WITHOUT PROPOSAL
    function testCreateDeal() public {
        address provider = vm.addr(5);
        address client = vm.addr(6);
        vm.deal(provider, 100 ether);
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );
        assertEq(
            retriev.isProvider(provider),
            true
        );
        // Start making calls with provider's key
        vm.startPrank(provider);
        uint256 duration = retriev.min_duration();
        uint256 collateral = 1 wei;
        address[] memory appeal_addresses = new address[](1);
        appeal_addresses[0] = provider;
        retriev.createDeal{value: collateral}(
            client,
            "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            duration,
            appeal_addresses
        );
    }

    // CREATE DEAL WITHOUT PROPOSAL
    function testCreateDealAndCancelPrematurely() public {
        address provider = vm.addr(5);
        address client = vm.addr(6);
        vm.deal(provider, 100 ether);
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );
        assertEq(
            retriev.isProvider(provider),
            true
        );
        // Start making calls with provider's key
        vm.startPrank(provider);
        uint256 duration = retriev.min_duration();
        uint256 collateral = 1 wei;
        address[] memory appeal_addresses = new address[](1);
        appeal_addresses[0] = provider;
        retriev.createDeal{value: collateral}(
            client,
            "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            duration,
            appeal_addresses
        );
        vm.stopPrank();

        vm.startPrank(client);
        // try to cancel prematurely
        vm.expectRevert("Deal Accepted already, cannot be cancelled");
        retriev.cancelDealProposal(1);
    }

    // CREATE DEAL WITHOUT PROPOSAL AND ACCEPT
    function testCreateDealAndAppeal() public {
        address provider = vm.addr(5);
        address client = vm.addr(6);
        vm.deal(provider, 100 ether);
        retriev.setProviderStatus(
            provider,
            true,
            "http://localhost:8000"
        );
        assertEq(
            retriev.isProvider(provider),
            true
        );
        // Start making calls with provider's key
        vm.startPrank(provider);
        uint256 duration = retriev.min_duration();
        uint256 collateral = 1 wei;
        address[] memory appeal_addresses = new address[](1);
        appeal_addresses[0] = provider;
        retriev.createDeal{value: collateral}(
            client,
            "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
            duration,
            appeal_addresses
        );
        // Create appeal
        retriev.createAppeal{value: 0}(1);
    }
}