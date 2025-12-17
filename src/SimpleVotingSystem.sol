// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    address public owner;
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addCandidate(string memory _name) public onlyOwner {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public {
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    // Optional: Function to get candidate details by ID
    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }
}
