// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DiskRegistry
/// @notice Registry of storage providers
contract DiskRegistry is Ownable {
    struct Provider {
        address providerAddress;
        string name;
        string metadataURI;
        bool approved;
        uint256 createdAt;
    }

    mapping(address => Provider) public providers;
    address[] public providerList;

    event ProviderRegistered(address indexed provider, string name, string metadataURI);
    event ProviderApproved(address indexed provider, bool approved);
    event ProviderUpdated(address indexed provider, string name, string metadataURI);

    // fix for OZ v5: pass owner to Ownable
    constructor() Ownable(msg.sender) {}

    function registerProvider(string calldata name, string calldata metadataURI) external {
        Provider storage p = providers[msg.sender];
        require(p.providerAddress == address(0), "Already registered");
        providers[msg.sender] = Provider({
            providerAddress: msg.sender,
            name: name,
            metadataURI: metadataURI,
            approved: false,
            createdAt: block.timestamp
        });
        providerList.push(msg.sender);
        emit ProviderRegistered(msg.sender, name, metadataURI);
    }

    function setProviderApproval(address providerAddr, bool approved) external onlyOwner {
        Provider storage p = providers[providerAddr];
        require(p.providerAddress != address(0), "Not registered");
        p.approved = approved;
        emit ProviderApproved(providerAddr, approved);
    }

    function updateProvider(string calldata name, string calldata metadataURI) external {
        Provider storage p = providers[msg.sender];
        require(p.providerAddress != address(0), "Not registered");
        p.name = name;
        p.metadataURI = metadataURI;
        emit ProviderUpdated(msg.sender, name, metadataURI);
    }

    function isApproved(address providerAddr) external view returns (bool) {
        return providers[providerAddr].approved;
    }

    function getProvidersCount() external view returns (uint256) {
        return providerList.length;
    }
}
