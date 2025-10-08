// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDiskRegistry {
    function isApproved(address providerAddr) external view returns (bool);
}

/// @title DiskMarketplace
contract DiskMarketplace is ReentrancyGuard, Ownable {
    IDiskRegistry public registry;
    address public fileRegistry; // for stronger integration, set after deployment

    struct Listing {
        uint256 id;
        address provider;
        uint256 spaceGB;
        uint256 pricePerDay;
        uint256 availableFrom;
        bool active;
        string metadataURI;
    }

    struct Rental {
        uint256 id;
        uint256 listingId;
        address renter;
        uint256 startAt;
        uint256 endAt;
        uint256 paidAmount;
        bool active;
    }

    uint256 public nextListingId = 1;
    uint256 public nextRentalId = 1;

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Rental) public rentals;
    mapping(address => uint256) public providerBalances;

    event ListingCreated(uint256 indexed listingId, address indexed provider, uint256 spaceGB, uint256 pricePerDay);
    event ListingUpdated(uint256 indexed listingId);
    event ListingDeactivated(uint256 indexed listingId);
    event Rented(uint256 indexed rentalId, uint256 indexed listingId, address indexed renter, uint256 startAt, uint256 endAt, uint256 paidAmount);
    event ProviderWithdraw(address indexed provider, uint256 amount);
    event FileRegistrySet(address indexed fileRegistry);

    constructor(address registryAddress) Ownable(msg.sender) {
        require(registryAddress != address(0), "Invalid registry");
        registry = IDiskRegistry(registryAddress);
    }

    modifier onlyApprovedProvider() {
        require(registry.isApproved(msg.sender), "Not approved provider");
        _;
    }

    function setFileRegistry(address _fileRegistry) external onlyOwner {
        require(_fileRegistry != address(0), "zero addr");
        fileRegistry = _fileRegistry;
        emit FileRegistrySet(_fileRegistry);
    }

    function createListing(uint256 spaceGB, uint256 pricePerDayWei, uint256 availableFrom, string calldata metadataURI) external onlyApprovedProvider {
        require(spaceGB > 0 && pricePerDayWei > 0, "invalid params");
        uint256 lid = nextListingId++;
        listings[lid] = Listing({
            id: lid,
            provider: msg.sender,
            spaceGB: spaceGB,
            pricePerDay: pricePerDayWei,
            availableFrom: availableFrom,
            active: true,
            metadataURI: metadataURI
        });
        emit ListingCreated(lid, msg.sender, spaceGB, pricePerDayWei);
    }

    function updateListing(uint256 listingId, uint256 spaceGB, uint256 pricePerDayWei, uint256 availableFrom, bool active, string calldata metadataURI) external {
        Listing storage l = listings[listingId];
        require(l.id != 0, "not found");
        require(l.provider == msg.sender || msg.sender == owner(), "unauth");
        l.spaceGB = spaceGB;
        l.pricePerDay = pricePerDayWei;
        l.availableFrom = availableFrom;
        l.active = active;
        l.metadataURI = metadataURI;
        emit ListingUpdated(listingId);
    }

    function deactivateListing(uint256 listingId) external {
        Listing storage l = listings[listingId];
        require(l.id != 0, "not found");
        require(l.provider == msg.sender || msg.sender == owner(), "unauth");
        l.active = false;
        emit ListingDeactivated(listingId);
    }

    function rentListing(uint256 listingId, uint256 durationDays) external payable nonReentrant {
        Listing memory l = listings[listingId];
        require(l.id != 0 && l.active, "Listing inactive");
        require(block.timestamp >= l.availableFrom, "Not available");
        require(durationDays > 0, "duration 0");
        uint256 required = l.pricePerDay * durationDays;
        require(msg.value == required, "incorrect payment");

        uint256 rid = nextRentalId++;
        uint256 startAt = block.timestamp;
        uint256 endAt = block.timestamp + (durationDays * 1 days);

        rentals[rid] = Rental({
            id: rid,
            listingId: listingId,
            renter: msg.sender,
            startAt: startAt,
            endAt: endAt,
            paidAmount: msg.value,
            active: true
        });

        providerBalances[l.provider] += msg.value;

        // If fileRegistry set, call its setter (optional, off-chain can set too)
        if (fileRegistry != address(0)) {
            // FileRegistry(fileRegistry).setRentalRoles is not interfaced here to avoid circular deps.
            // The backend should call fileRegistry.setRentalRoles(rid, renter, provider).
        }

        emit Rented(rid, listingId, msg.sender, startAt, endAt, msg.value);
    }

    function withdrawProvider() external nonReentrant {
        uint256 bal = providerBalances[msg.sender];
        require(bal > 0, "no balance");
        providerBalances[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: bal}("");
        require(sent, "send fail");
        emit ProviderWithdraw(msg.sender, bal);
    }

    function setRegistry(address registryAddress) external onlyOwner {
        require(registryAddress != address(0), "invalid");
        registry = IDiskRegistry(registryAddress);
    }

    function getListing(uint256 id) external view returns (Listing memory) { return listings[id]; }
    function getRental(uint256 id) external view returns (Rental memory) { return rentals[id]; }
}
