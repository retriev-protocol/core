// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./STATE.sol";

contract PROVIDER is STATE, Ownable {
    /*
        This method will say if address is a provider or not
    */
    function providerExists(address check) public view returns (bool) {
        return providers[check]._exists;
    }

    /*
        This method will allow owner to remove a provider
    */
    function removeProvider(address _provider) external onlyOwner {
        delete providers[_provider];
    }

    /*
        This method will allow owner to enable or disable a provider
    */
    function setProviderStatus(address _provider, bool _state, string memory _endpoint) external {
        require(_provider != address(0x0), "Invalid address");
        if (permissioned_providers) {
            require(msg.sender == owner(), "Only owner can manage providers");
        } else {
            require(
                _provider == msg.sender || msg.sender == owner(),
                "You can't manage another provider's state"
            );
        }
        providers[_provider].active = _state;
        providers[_provider].endpoint = _endpoint;
        // KS-PLW-02: Duplicate provider address is allowed
        if (_state && providers[_provider]._exists == false) {
            providers[_provider]._exists = true;
            active_providers.push(_provider);
        } else {
            for (uint256 i = 0; i < active_providers.length; i++) {
                if (active_providers[i] == _provider) {
                    // KS-PLW-07: Vault Deposit Not Returned to Outgoing Provider
                    require(vault[_provider] == 0, "Provider Vault is not empty");
                    delete active_providers[i];
                }
            }
        }
    }
}
