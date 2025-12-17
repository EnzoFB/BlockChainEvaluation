// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SimpleVotingNFT.sol";

contract SimpleVotingSystem is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    enum WorkflowStatus { REGISTER_CANDIDATES, FOUND_CANDIDATES, VOTE, COMPLETED }
    WorkflowStatus public workflowStatus;

    mapping(uint => uint256) public candidateFunds;

    uint256 public voteStartSetAt;
    
    SimpleVotingNFT public votingNFT;

    constructor(address _votingNFT) {
        _grantRole(ADMIN_ROLE, msg.sender);
        votingNFT = SimpleVotingNFT(_votingNFT);
    }

    function addCandidate(string memory _name) public onlyRole(ADMIN_ROLE) {
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Wrong phase");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public {
        require(workflowStatus == WorkflowStatus.VOTE, "Wrong phase");
        require(votingNFT.balanceOf(msg.sender) == 0, "You have already voted (NFT detected)");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(block.timestamp >= voteStartSetAt + 1 hours, "Voting not open yet");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
        votingNFT.mint(msg.sender);
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

    function setWorkflowStatus(WorkflowStatus newStatus) external onlyRole(ADMIN_ROLE) {
        workflowStatus = newStatus;
        if (newStatus == WorkflowStatus.VOTE) {
            voteStartSetAt = block.timestamp;
        }
    }

    function grantFounder(address a) external onlyRole(ADMIN_ROLE) {
        _grantRole(FOUNDER_ROLE, a);
    }

    function fundCandidate(uint candidateId) external payable onlyRole(FOUNDER_ROLE) {
        candidateFunds[candidateId] += msg.value;
    }

    function getWinner() public view returns (uint winnerId, string memory winnerName, uint winnerVoteCount) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Voting not completed yet");
        require(candidateIds.length > 0, "No candidates registered");
        
        uint maxVotes = 0;
        uint winningCandidateId = 0;
        
        for (uint i = 0; i < candidateIds.length; i++) {
            uint candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winningCandidateId = candidateId;
            }
        }
        
        require(winningCandidateId > 0, "No winner found");
        Candidate memory winner = candidates[winningCandidateId];
        return (winner.id, winner.name, winner.voteCount);
    }
}
