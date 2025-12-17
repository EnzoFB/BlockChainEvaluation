// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SimpleVotingNFT.sol";

contract SimpleVotingSystem is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint256[] private candidateIds;

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }
    WorkflowStatus public workflowStatus;

    mapping(uint256 => uint256) public candidateFunds;

    uint256 public voteStartSetAt;

    SimpleVotingNFT public votingNFT;

    constructor(address _votingNFT) {
        _grantRole(ADMIN_ROLE, msg.sender);
        votingNFT = SimpleVotingNFT(_votingNFT);
    }

    function addCandidate(string memory _name) public onlyRole(ADMIN_ROLE) {
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Wrong phase");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint256 candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint256 _candidateId) public {
        require(workflowStatus == WorkflowStatus.VOTE, "Wrong phase");
        require(votingNFT.balanceOf(msg.sender) == 0, "You have already voted (NFT detected)");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(block.timestamp >= voteStartSetAt + 1 hours, "Voting not open yet");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
        votingNFT.mint(msg.sender);
    }

    function getTotalVotes(uint256 _candidateId) public view returns (uint256) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint256) {
        return candidateIds.length;
    }

    // Optional: Function to get candidate details by ID
    function getCandidate(uint256 _candidateId) public view returns (Candidate memory) {
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

    function fundCandidate(uint256 candidateId) external payable onlyRole(FOUNDER_ROLE) {
        require(workflowStatus == WorkflowStatus.FOUND_CANDIDATES, "Wrong phase");
        candidateFunds[candidateId] += msg.value;
    }

    function getWinner() public view returns (uint256 winnerId, string memory winnerName, uint256 winnerVoteCount) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Voting not completed yet");
        require(candidateIds.length > 0, "No candidates registered");

        uint256 maxVotes = 0;
        uint256 winningCandidateId = 0;

        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];
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
