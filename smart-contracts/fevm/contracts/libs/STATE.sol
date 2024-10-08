// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../functions/render/IRENDER.sol";

contract STATE {
    // Defining structs
    struct Referee {
        bool active;
        string endpoint;
    }
    struct Provider {
        bool active;
        string endpoint;
        bool _exists;
    }
    struct Deal {
        // subject of the deal
        string data_uri;
        // Timestamp request
        uint256 timestamp_request;
        // Starting timestamp
        uint256 timestamp_start;
        // Duration of deal expressed in seconds
        uint256 duration;
        // Amount in wei paid for the deal
        uint256 value;
        // Amount in wei needed to accept the deal
        uint256 collateral;
        // Address of provider
        mapping(address => bool) providers;
        // Address of owner
        address owner;
        // Describe if deal is canceled or not
        bool canceled;
        // Addresses authorized to create appeals
        mapping(address => bool) appeal_addresses;
    }
    // Defining appeal struct
    struct Appeal {
        // Index object of the deal
        uint256 deal_index;
        // Describe if appeal is active or not
        bool active;
        // Mapping that stores what rounds were processed
        mapping(uint256 => bool) processed;
        // Counter for slashes
        uint128 slashes;
        // Block timestamp of deal creation
        uint256 request_timestamp;
        // Adding block timestamp to calculate timeout
        uint256 origin_timestamp;
    }
    // Mapping admin roles
    mapping(uint8 => mapping(address => bool)) public admins;
    // Mapping referees addresses
    mapping(address => Referee) public referees;
    // Array of active referees
    address[] public active_referees;
    // Multipliers
    uint256 public slashing_multiplier = 1000;
    uint8 public committee_divider = 4;
    // Deal parameters
    uint32 public proposal_timeout = 86_400;
    uint32 public appeal_timeout = 86_400;
    uint8 public max_appeals = 5;
    uint256 public min_deal_value = 0;
    // Round parameters
    uint32 public round_duration = 300;
    uint32 public min_duration = 86_400;
    uint32 public max_duration = 31_536_000;
    uint8 public slashes_threshold = 12;
    uint8 public rounds_limit = 12;
    // Contract state variables
    bool public contract_protected = true;
    bool public permissioned_providers = false;
    // Protocol address
    address protocol_address;
    // Render contract
    IRENDER internal token_render;
    // Mapping referees providers
    mapping(address => Provider) public providers;
    // Array of active providers
    address[] public active_providers;
    // Mapping deals
    mapping(uint256 => Deal) public deals;
    // Mapping appeals
    mapping(uint256 => Appeal) public appeals;
    // Mapping pending appeals using data_uri as index
    mapping(string => uint256) public pending_appeals;
    // Mapping active appeals using data_uri as index
    mapping(string => uint256) public active_appeals;
    // Mapping all appeals using deal_index as index
    mapping(uint256 => uint8) public tot_appeals;
    // Referee, Providers and Clients vault
    mapping(address => uint256) public vault;
}
