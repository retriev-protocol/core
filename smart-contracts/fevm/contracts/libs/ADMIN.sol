// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./STATE.sol";

contract ADMIN is STATE, Ownable {
    /*
        Admin function to setup roles
    */

    function setRole(uint8 kind, bool status, address admin) external onlyOwner {
        // Set specified role, using:
        // 1 - Protocol managers
        // 2 - Referees managers
        // 3 - Providers managers
        admins[kind][admin] = status;
    }

    /*
        Admin functions to fine tune protocol
    */
    // function tuneRefereesVariables(
    //     uint8 kind,
    //     uint8 value8,
    //     uint32 value32
    // ) external {
    //     require(
    //         msg.sender == owner() || admins[2][msg.sender],
    //         "Can't manage referees variables"
    //     );
    //     if (kind == 0) {
    //         committee_divider = value8;
    //     } else if (kind == 1) {
    //         max_appeals = value8;
    //     } else if (kind == 2) {
    //         round_duration = value32;
    //     } else if (kind == 3) {
    //         rounds_limit = value8;
    //     } else if (kind == 4) {
    //         slashes_threshold = value8;
    //     }
    // }

    // function tuneProvidersVariables(
    //     uint8 kind,
    //     uint256 value256,
    //     uint32 value32
    // ) external {
    //     require(
    //         msg.sender == owner() || admins[3][msg.sender],
    //         "Can't manage providers variables"
    //     );
    //     if (kind == 0) {
    //         proposal_timeout = value32;
    //     } else if (kind == 1) {
    //         min_deal_value = value256;
    //     } else if (kind == 2) {
    //         slashing_multiplier = value256;
    //     } else if (kind == 3) {
    //         min_duration = value32;
    //     } else if (kind == 4) {
    //         max_duration = value32;
    //     } else if (kind == 5) {
    //         appeal_timeout = value32;
    //     }
    // }

    function tuneProtocolVariables(
        uint8 kind,
        address addy,
        bool state
    ) external {
        require(
            msg.sender == owner() || admins[1][msg.sender],
            "Can't manage protocol variables"
        );
        if (kind == 0) {
            token_render = IRENDER(addy);
        } else if (kind == 1) {
            protocol_address = addy;
        } else if (kind == 2) {
            contract_protected = state;
        } else if (kind == 3) {
            permissioned_providers = state;
        }
    }

    /*
        This method safely removes an active referee from it's corresponding array,
        part of KS-PLW-06: Removal of referee adds null address to array index
    */
    function removeActiveReferee(uint _index) private {
        require(_index < active_referees.length, "index out of bound");

        for (uint i = _index; i < active_referees.length - 1; i++) {
            active_referees[i] = active_referees[i + 1];
        }
        active_referees.pop();
    }

    /*
        This method will allow owner to enable or disable a referee
    */
    function setRefereeStatus(
        address _referee,
        bool _state,
        string memory _endpoint
    ) external onlyOwner {
        if (_state) {
            // KS-PLW-05: Duplicate referee address is allowed
            if (!referees[_referee].active) {
                active_referees.push(_referee);
            }
            referees[_referee].active = _state;
            referees[_referee].endpoint = _endpoint;
        } else {
            for (uint256 i = 0; i < active_referees.length; i++) {
                if (active_referees[i] == _referee) {
                    // KS-PLW-06: Removal of referee adds null address to array index
                    removeActiveReferee(i);
                }
            }
        }
    }
}
