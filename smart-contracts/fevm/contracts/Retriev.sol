// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libs/ERC721.sol";
import "./libs/ADMIN.sol";
import "./libs/PROVIDER.sol";
import "./libs/STATE.sol";
import "./functions/render/IRENDER.sol";

/**
 * @title Retriev (retriev.org)
 * Implementation of retrievability protocol
 * described at: https://retriev.org/paper
 */
contract Retriev is ERC721, Ownable, ReentrancyGuard, ADMIN, PROVIDER {
    // Internal counters for deals and appeals mapping
    uint256 private dealCounter;
    uint256 private appealCounter;
    // Event emitted when new deal is created
    event DealProposalCreated(
        uint256 index,
        address[] providers,
        string data_uri,
        address[] appeal_addresses
    );

    // Event emitted when a deal is canceled before being accepted
    event DealProposalCanceled(uint256 index);
    // Event emitted when a deal is redeemed
    event DealRedeemed(uint256 index);
    // Event emitted when new appeal is created
    event AppealCreated(uint256 index, address provider, string data_uri);
    // Event emitted when new appeal started
    event AppealStarted(uint256 index);
    // Event emitted when a slash message is recorded
    event RoundSlashed(uint256 index);
    // Event emitted when a deal is invalidated by an appeal
    event DealInvalidated(uint256 index);

    constructor(address _protocol_address, address _render) ERC721("Retriev", "RTV") {
        require(_protocol_address != address(0), "Can't init protocol with black-hole");
        protocol_address = _protocol_address;
        token_render = IRENDER(_render);
    }

    function totalSupply() public view returns (uint256) {
        return dealCounter;
    }

    function totalDeals() external view returns (uint256) {
        return dealCounter;
    }

    function totalAppeals() external view returns (uint256) {
        return appealCounter;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        Deal storage deal = deals[tokenId];
        string memory output = token_render.render(
            tokenId,
            deal.data_uri,
            deal.value,
            deal.timestamp_start,
            deal.duration,
            getRound(active_appeals[deals[tokenId].data_uri]) < 99,
            deal.owner
        );
        return output;
    }

    function balanceOf(address _to_check) public view virtual override returns (uint256) {
        uint256 totalTkns = totalSupply();
        uint256 resultIndex = 0;
        uint256 tnkId;

        for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
            if (ownerOf(tnkId) == _to_check) {
                resultIndex++;
            }
        }

        return resultIndex;
    }

    /*
        This method verifies a signature
    */
    function verifyRefereeSignature(
        bytes memory _signature,
        uint256 deal_index,
        address referee
    ) public view returns (bool) {
        require(referees[referee].active, "Provided address is not a referee");
        bytes memory message = getPrefix(deal_index);
        bytes32 hashed = ECDSA.toEthSignedMessageHash(message);
        address recovered = ECDSA.recover(hashed, _signature);
        return recovered == referee;
    }

    /*
        This method returns the prefix for
    */
    function getPrefix(uint256 appeal_index) public view returns (bytes memory) {
        uint256 deal_index = appeals[appeal_index].deal_index;
        uint256 round = getRound(appeal_index);
        return
            abi.encodePacked(
                Strings.toString(deal_index),
                Strings.toString(appeal_index),
                Strings.toString(round)
            );
    }

    /*
        This method will return the amount in ETH needed to create an appeal
    */
    function returnAppealFee(uint256 deal_index) public view returns (uint256) {
        uint256 fee = deals[deal_index].value / committee_divider;
        return fee;
    }

    /*
        This method will return the amount of signatures needed to close a rount
    */
    function refereeConsensusThreshold() public view returns (uint256) {
        uint256 half = (active_referees.length * 100) / 2;
        return half;
    }

    /*
        This method will return the leader for a provided appeal
    */
    function getElectedLeader(uint256 appeal_index) public view returns (address) {
        uint256 round = getRound(appeal_index);
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(appeals[appeal_index].origin_timestamp + appeal_index + round)
            )
        );
        uint256 leader = (seed - ((seed / active_referees.length) * active_referees.length));
        return active_referees[leader];
    }

    /*
        This method will return the round for provided appeal
    */
    function getRound(uint256 appeal_index) public view returns (uint256) {
        if (appeals[appeal_index].origin_timestamp > 0) {
            uint256 appeal_duration = round_duration * rounds_limit;
            uint256 appeal_end = appeals[appeal_index].origin_timestamp + appeal_duration;
            if (appeal_end >= block.timestamp) {
                uint256 remaining_time = appeal_end - block.timestamp;
                uint256 remaining_rounds = remaining_time / round_duration;
                uint256 round = rounds_limit - remaining_rounds;
                return round;
            } else {
                // Means appeal is ended
                return 99;
            }
        } else {
            // Means appeal is never started
            return 0;
        }
    }

    /*
        This method will allow client to create a deal
    */
    function createDealProposal(
        string memory _data_uri,
        uint256 duration,
        uint256 collateral,
        address[] memory _providers,
        address[] memory _appeal_addresses
    ) external payable nonReentrant {
        if (contract_protected) {
            require(msg.value == 0, "Contract is protected, can't accept value");
        }
        require(
            duration >= min_duration && duration <= max_duration,
            "Duration is out allowed range"
        );
        // uint256 maximum_collateral = slashing_multiplier * msg.value;
        require(
            msg.value >= min_deal_value,
            // && collateral >= msg.value && collateral <= maximum_collateral
            "Collateral or value out of range"
        );
        require(_appeal_addresses.length > 0, "You must define one or more appeal addresses");
        require(_providers.length > 0, "You must define one or more providers");
        // Creating next id
        dealCounter++;
        uint256 index = dealCounter;
        // Creating the deal mapping
        deals[index].timestamp_request = block.timestamp;
        deals[index].owner = msg.sender;
        deals[index].data_uri = _data_uri;
        deals[index].duration = duration;
        deals[index].collateral = collateral;
        deals[index].value = msg.value;
        // Check if provided providers are active and store in struct
        for (uint256 i = 0; i < _providers.length; i++) {
            require(providers[_providers[i]].active, "Requested provider is not active");
            deals[index].providers[_providers[i]] = true;
        }
        // Add appeal addresses to deal
        for (uint256 i = 0; i < _appeal_addresses.length; i++) {
            deals[index].appeal_addresses[_appeal_addresses[i]] = true;
        }
        // When created the amount of money is owned by sender
        vault[address(this)] += msg.value;
        // Emit event
        emit DealProposalCreated(index, _providers, _data_uri, _appeal_addresses);
    }

    /*
        This method will allow provider create deal without a proposal
    */
    function createDeal(
        address _owner,
        string memory _data_uri,
        uint256 duration,
        address[] memory _appeal_addresses
    ) external payable nonReentrant {
        require(
            duration >= min_duration && duration <= max_duration,
            "Duration is out allowed range"
        );
        require(_appeal_addresses.length > 0, "You must define one or more appeal addresses");
        require(providers[msg.sender].active, "Only providers can create deals without proposal");
        // Creating next id
        dealCounter++;
        uint256 index = dealCounter;
        // Creating the deal mapping
        deals[index].owner = _owner;
        deals[index].timestamp_start = block.timestamp;
        deals[index].data_uri = _data_uri;
        deals[index].duration = duration;
        deals[index].collateral = msg.value;
        // Add appeal addresses to deal
        for (uint256 i = 0; i < _appeal_addresses.length; i++) {
            deals[index].appeal_addresses[_appeal_addresses[i]] = true;
        }
        // Add collateral to contract's vault
        vault[address(this)] += msg.value;
        // Mint the NFT representing the deal
        _mint(msg.sender, index);
    }

    /*
        This method will allow client to cancel deal if not accepted
    */
    function cancelDealProposal(uint256 deal_index) external nonReentrant {
        require(deals[deal_index].owner == msg.sender, "Only owner can cancel the deal");
        require(!deals[deal_index].canceled, "Deal canceled yet");
        // KS-PLW-03: Client can cancel the deal after it is accepted
        require(
            block.timestamp > (deals[deal_index].timestamp_start + deals[deal_index].duration),
            "Deal Accepted already, cannot be cancelled"
        );

        deals[deal_index].canceled = true;
        deals[deal_index].timestamp_start = 0;
        // Remove funds from internal vault giving back to user
        // user will be able to withdraw funds later
        vault[address(this)] -= deals[deal_index].value;
        vault[msg.sender] += deals[deal_index].value;
        emit DealProposalCanceled(deal_index);
    }

    /*
        This method will return provider status in deal
    */
    function isProviderInDeal(uint256 deal_index, address provider) external view returns (bool) {
        return deals[deal_index].providers[provider];
    }

    /*
        This method will return appeal address status in deal
    */
    function canAddressAppeal(
        uint256 deal_index,
        address appeal_address
    ) external view returns (bool) {
        return deals[deal_index].appeal_addresses[appeal_address];
    }

    /*
        This method will allow a provider to accept a deal
    */
    function acceptDealProposal(uint256 deal_index) external nonReentrant {
        require(
            block.timestamp < (deals[deal_index].timestamp_request + proposal_timeout) &&
                !deals[deal_index].canceled &&
                deals[deal_index].providers[msg.sender],
            "Deal expired, canceled or not allowed to accept"
        );
        require(
            vault[msg.sender] >= deals[deal_index].collateral,
            "Can't accept because you don't have enough balance in contract"
        );
        // Mint the nft to the provider
        _mint(msg.sender, deal_index);
        // Activate contract
        deals[deal_index].timestamp_start = block.timestamp;
        // Deposit collateral to contract
        vault[msg.sender] -= deals[deal_index].collateral;
        vault[address(this)] += deals[deal_index].collateral;
    }

    /*
        This method will allow provider to withdraw funds for deal
    */
    function redeemDeal(uint256 deal_index) external nonReentrant {
        require(ownerOf(deal_index) == msg.sender, "Only provider can redeem");
        require(deals[deal_index].timestamp_start > 0, "Deal is not active");
        uint256 timeout = deals[deal_index].timestamp_start + deals[deal_index].duration;
        require(block.timestamp > timeout, "Deal didn't ended, can't redeem");
        require(
            pending_appeals[deals[deal_index].data_uri] == 0 ||
                (appeals[pending_appeals[deals[deal_index].data_uri]].request_timestamp +
                    appeal_timeout) <
                block.timestamp,
            "Found a pending appeal, can't redeem"
        );
        require(
            getRound(active_appeals[deals[deal_index].data_uri]) >= 99,
            "Found an active appeal, can't redeem"
        );
        // KS-PLW-04: Dealer can claim bounty when deal is cancelled
        require(!deals[deal_index].canceled, "Deal already cancelled");

        // Move value from contract to address
        vault[address(this)] -= deals[deal_index].value;
        vault[msg.sender] += deals[deal_index].value;

        // Giving back collateral to provider
        vault[address(this)] -= deals[deal_index].collateral;
        vault[msg.sender] += deals[deal_index].collateral;
        // Close the deal
        deals[deal_index].timestamp_start = 0;
        emit DealRedeemed(deal_index);
    }

    /*
        This method will allow client to create an appeal
    */
    function createAppeal(uint256 deal_index) external payable nonReentrant {
        require(tot_appeals[deal_index] < max_appeals, "Can't create more appeals on deal");
        require(deals[deal_index].timestamp_start > 0, "Deal is not active");
        require(
            block.timestamp <
                ((deals[deal_index].timestamp_start + deals[deal_index].duration) -
                    (round_duration * rounds_limit * 2)),
            "Appeal time expired, can't create appeals"
        );
        // Check if appeal address was listed
        require(
            deals[deal_index].appeal_addresses[msg.sender],
            "Only authorized addresses can create appeal"
        );
        // Check if there's a pending appeal request or the pending request expired
        require(
            pending_appeals[deals[deal_index].data_uri] == 0 ||
                (appeals[pending_appeals[deals[deal_index].data_uri]].request_timestamp +
                    appeal_timeout) <
                block.timestamp,
            "There's a pending appeal request"
        );
        // Check if appeal exists or is expired
        require(
            active_appeals[deals[deal_index].data_uri] == 0 ||
                // Check if appeal is expired
                getRound(active_appeals[deals[deal_index].data_uri]) >= 99,
            "Appeal exists yet for provided hash"
        );
        // Be sure sent amount is exactly the appeal fee
        require(
            msg.value == returnAppealFee(deal_index),
            "Must send exact fee to create an appeal"
        );
        // Increase the number of appeals
        tot_appeals[deal_index]++;
        // Split fee to referees
        if (msg.value > 0) {
            uint256 fee = msg.value / active_referees.length;
            for (uint256 i = 0; i < active_referees.length; i++) {
                vault[active_referees[i]] += fee;
            }
        }
        // Creating next id
        appealCounter++;
        uint256 index = appealCounter;
        // Storing appeal status
        pending_appeals[deals[deal_index].data_uri] = index;
        // Creating appeal
        appeals[index].deal_index = deal_index;
        appeals[index].active = true;
        appeals[index].request_timestamp = block.timestamp;
        // Emit appeal created event
        emit AppealCreated(index, ownerOf(deal_index), deals[deal_index].data_uri);
    }

    /*
        This method will allow referees to start an appeal
    */
    function startAppeal(uint256 appeal_index) external {
        require(appeals[appeal_index].origin_timestamp == 0, "Appeal started yet");
        require(referees[msg.sender].active, "Only referees can start appeals");
        appeals[appeal_index].origin_timestamp = block.timestamp;
        // Reset pending appeal state
        pending_appeals[deals[appeals[appeal_index].deal_index].data_uri] = 0;
        // Set active appeal state
        active_appeals[deals[appeals[appeal_index].deal_index].data_uri] = appeal_index;
        // Emit appeal created event
        emit AppealStarted(appeal_index);
    }

    /*
        This method checks for duplicate signatures
    */
    function checkDuplicate(bytes[] memory _arr) internal pure returns (bool) {
        if (_arr.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < _arr.length - 1; i++) {
            for (uint256 j = i + 1; j < _arr.length; j++) {
                if (sha256(_arr[i]) == sha256(_arr[j])) {
                    return true;
                }
            }
        }
        return false;
    }

    /*
        This method will allow referees to process an appeal
    */
    function processAppeal(
        uint256 deal_index,
        address[] memory _referees,
        bytes[] memory _signatures
    ) external {
        uint256 appeal_index = active_appeals[deals[deal_index].data_uri];
        uint256 round = getRound(appeal_index);
        // KS-PLW-01: Duplicate Signatures are not checked while processing an appeal
        require(!checkDuplicate(_signatures), "processAppeal: Duplicate signatures");
        require(deals[deal_index].timestamp_start > 0, "Deal is not active");
        require(appeals[appeal_index].active, "Appeal is not active");
        require(referees[msg.sender].active, "Only referees can process appeals");
        require(round <= rounds_limit, "This appeal can't be processed anymore");
        require(!appeals[appeal_index].processed[round], "This round was processed yet");
        appeals[appeal_index].processed[round] = true;
        bool slashed = false;
        if (getElectedLeader(appeal_index) == msg.sender) {
            appeals[appeal_index].slashes++;
            slashed = true;
        } else {
            for (uint256 i = 0; i < _referees.length; i++) {
                address referee = _referees[i];
                bytes memory signature = _signatures[i];
                // Be sure leader is not hacking the system
                require(
                    verifyRefereeSignature(signature, deal_index, referee),
                    "Signature doesn't matches"
                );
            }
            if ((_signatures.length * 100) > refereeConsensusThreshold()) {
                appeals[appeal_index].slashes++;
                slashed = true;
            }
        }
        require(slashed, "Appeal wasn't slashed, not the leader or no consensus");
        emit RoundSlashed(appeal_index);
        if (appeals[appeal_index].slashes >= slashes_threshold) {
            deals[deal_index].timestamp_start = 0;
            appeals[appeal_index].active = false;
            // Return value of deal back to owner
            vault[address(this)] -= deals[deal_index].value;
            vault[deals[deal_index].owner] += deals[deal_index].value;
            // Remove funds from provider and charge provider
            uint256 collateral = deals[deal_index].collateral;
            vault[address(this)] -= collateral;
            // All collateral to protocol's address:
            vault[protocol_address] += collateral;
            // Split collateral between client and protocol:
            // -> vault[protocol_address] += collateral / 2;
            // -> vault[deals[deal_index].owner] += collateral / 2;
            emit DealInvalidated(deal_index);
        }
    }

    /*
        This method will allow provider deposit ETH in order to accept deals
    */
    function depositToVault() external payable nonReentrant {
        require(providers[msg.sender].active, "Only providers can deposit into contract");
        require(msg.value > 0, "Must send some value");
        vault[msg.sender] += msg.value;
    }

    /*
        This method will allow to withdraw ethers from contract
    */
    function withdrawFromVault(uint256 amount) external nonReentrant {
        uint256 balance = vault[msg.sender];
        require(balance >= amount, "Not enough balance to withdraw");
        vault[msg.sender] -= amount;
        bool success;
        (success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw to user failed");
    }
}
