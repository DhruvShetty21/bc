// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FileRegistry {
    address public marketplace; // only marketplace allowed to set roles initially

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "only marketplace");
        _;
    }

    constructor(address _marketplace) {
        marketplace = _marketplace;
    }

    struct Chunk {
        string cid;
        uint256 index;
        string metadata;
        uint256 addedAt;
    }

    mapping(uint256 => mapping(uint256 => Chunk)) private chunks;
    mapping(uint256 => uint256) public chunkCount;
    mapping(uint256 => address) public rentalRenter;
    mapping(uint256 => address) public rentalProvider;

    event ChunkRegistered(uint256 indexed rentalId, uint256 indexed chunkIndex, string cid, address indexed by);
    event RentalRolesSet(uint256 indexed rentalId, address renter, address provider);

    // Only marketplace can set roles to prevent spoofing (marketplace calls this after rent created)
    function setRentalRoles(uint256 rentalId, address renter, address provider) external onlyMarketplace {
        rentalRenter[rentalId] = renter;
        rentalProvider[rentalId] = provider;
        emit RentalRolesSet(rentalId, renter, provider);
    }

    // Renter or provider registers chunks
    function registerChunk(uint256 rentalId, string calldata cid, string calldata metadata) external {
        require(rentalRenter[rentalId] != address(0), "roles unset");
        require(msg.sender == rentalRenter[rentalId] || msg.sender == rentalProvider[rentalId], "not authorized");
        uint256 idx = chunkCount[rentalId]++;
        chunks[rentalId][idx] = Chunk({ cid: cid, index: idx, metadata: metadata, addedAt: block.timestamp });
        emit ChunkRegistered(rentalId, idx, cid, msg.sender);
    }

    function getChunk(uint256 rentalId, uint256 idx) external view returns (Chunk memory) {
        return chunks[rentalId][idx];
    }
}
