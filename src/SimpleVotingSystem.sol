// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./SimpleVotingNFT.sol";

contract SimpleVotingSystem is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    // Custom Errors
    error WrongPhase(WorkflowStatus current, WorkflowStatus required);
    error AlreadyVoted(address voter);
    error InvalidCandidateId(uint256 id);
    error VotingNotOpenYet(uint256 currentTime, uint256 openTime);
    error EmptyCandidateName();
    error ZeroAmount();
    error NoCandidatesRegistered();
    error NoWinnerFound();

    // Events
    event CandidateAdded(uint256 indexed candidateId, string name);
    event Voted(address indexed voter, uint256 indexed candidateId);
    event WorkflowStatusChanged(WorkflowStatus oldStatus, WorkflowStatus newStatus);
    event CandidateFunded(uint256 indexed candidateId, uint256 amount, address indexed funder);
    event WinnerDeclared(uint256 indexed winnerId, string name, uint256 voteCount);

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
        if (workflowStatus != WorkflowStatus.REGISTER_CANDIDATES) {
            revert WrongPhase(workflowStatus, WorkflowStatus.REGISTER_CANDIDATES);
        }
        if (bytes(_name).length == 0) {
            revert EmptyCandidateName();
        }
        uint256 candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
        emit CandidateAdded(candidateId, _name);
    }

    function vote(uint256 _candidateId) public {
        if (workflowStatus != WorkflowStatus.VOTE) {
            revert WrongPhase(workflowStatus, WorkflowStatus.VOTE);
        }
        if (votingNFT.balanceOf(msg.sender) != 0) {
            revert AlreadyVoted(msg.sender);
        }
        if (_candidateId == 0 || _candidateId > candidateIds.length) {
            revert InvalidCandidateId(_candidateId);
        }
        if (block.timestamp < voteStartSetAt + 1 hours) {
            revert VotingNotOpenYet(block.timestamp, voteStartSetAt + 1 hours);
        }

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
        votingNFT.mint(msg.sender);
        emit Voted(msg.sender, _candidateId);
    }

    function getTotalVotes(uint256 _candidateId) public view returns (uint256) {
        if (_candidateId == 0 || _candidateId > candidateIds.length) {
            revert InvalidCandidateId(_candidateId);
        }
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint256) {
        return candidateIds.length;
    }

    // Optional: Function to get candidate details by ID
    function getCandidate(uint256 _candidateId) public view returns (Candidate memory) {
        if (_candidateId == 0 || _candidateId > candidateIds.length) {
            revert InvalidCandidateId(_candidateId);
        }
        return candidates[_candidateId];
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateIds.length);
        for (uint256 i = 0; i < candidateIds.length; i++) {
            allCandidates[i] = candidates[candidateIds[i]];
        }
        return allCandidates;
    }

    function setWorkflowStatus(WorkflowStatus newStatus) external onlyRole(ADMIN_ROLE) {
        WorkflowStatus oldStatus = workflowStatus;
        workflowStatus = newStatus;
        if (newStatus == WorkflowStatus.VOTE) {
            voteStartSetAt = block.timestamp;
        }
        emit WorkflowStatusChanged(oldStatus, newStatus);
    }

    function grantFounder(address a) external onlyRole(ADMIN_ROLE) {
        _grantRole(FOUNDER_ROLE, a);
    }

    function fundCandidate(uint256 candidateId) external payable onlyRole(FOUNDER_ROLE) {
        if (workflowStatus != WorkflowStatus.FOUND_CANDIDATES) {
            revert WrongPhase(workflowStatus, WorkflowStatus.FOUND_CANDIDATES);
        }
        if (candidateId == 0 || candidateId > candidateIds.length) {
            revert InvalidCandidateId(candidateId);
        }
        if (msg.value == 0) {
            revert ZeroAmount();
        }
        candidateFunds[candidateId] += msg.value;
        emit CandidateFunded(candidateId, msg.value, msg.sender);
    }

    function getWinner() public view returns (uint256 winnerId, string memory winnerName, uint256 winnerVoteCount) {
        if (workflowStatus != WorkflowStatus.COMPLETED) {
            revert WrongPhase(workflowStatus, WorkflowStatus.COMPLETED);
        }
        if (candidateIds.length == 0) {
            revert NoCandidatesRegistered();
        }

        uint256 maxVotes = 0;
        uint256 winningCandidateId = 0;

        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winningCandidateId = candidateId;
            }
        }

        if (winningCandidateId == 0) {
            revert NoWinnerFound();
        }
        Candidate memory winner = candidates[winningCandidateId];
        return (winner.id, winner.name, winner.voteCount);
    }
}
