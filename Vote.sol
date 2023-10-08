// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Vote is Ownable{
    constructor() Ownable(msg.sender) {
        
    }

    struct Voter {
        bool isRegistred;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] propositions;
    Voter[] voters;

    enum WorkflowStatus {RegisteringVoters, ProposalsRegistrationStarted, ProposalsRegistrationEnded, VotingSessionStarted, VotingSessionEnded, VotesTallied}
    WorkflowStatus public workflow ;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    mapping (address => Voter) voter;

    function whitelist(address _address) public onlyOwner {
        require(!voter[_address].isRegistred, "This address is already whitelisted !");
        voter[_address] = Voter(true, false, 0); 
        emit VoterRegistered(_address);
    }

    function proposalStarted() public onlyOwner {
        workflow = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, workflow);
    }

    function registrationProposal( string memory _description) public {
        require(workflow == WorkflowStatus.ProposalsRegistrationStarted, "La periode d'enregistrement n'est pas ouverte.");
        require(voter[msg.sender].isRegistred, "Vous n'etes pas enregistre dans la whitelist.");
        Proposal memory proposition = Proposal(_description, 0);
        propositions.push(proposition);
        emit ProposalRegistered(propositions.length - 1);
    }
    
    function proposalEnded() public onlyOwner {
        workflow = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, workflow);
    }

    function voteStarted() onlyOwner public {
        workflow = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, workflow);
    }

    function voteProposal(uint  _id) public {
        require(workflow == WorkflowStatus.VotingSessionStarted, "La periode de vote n'est pas ouverte.");
        require(voter[msg.sender].isRegistred, "Vous n'etes pas enregistre dans la whitelist.");
        propositions[_id -1].voteCount += 1;
        voter[msg.sender].hasVoted = true;
        voter[msg.sender].votedProposalId = _id ;
        emit Voted(msg.sender, _id);
    }

    function voteEnded() onlyOwner public {
        workflow = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, workflow);
    }

    function getWinner() view public returns(Proposal memory) {
        uint  _id;
        uint  count = 0;
        for(uint i = 0 ; i < propositions.length -1 ; i++) {
            if(propositions[i].voteCount > count) {
                count = propositions[i].voteCount;
                _id = i;
            }
        }
        return propositions[_id];
    }
    function verifVote(address _address) view public returns(uint) {
        // Cette fonction permet de vérifier le vote d'un electeur en fonction de son adresse.
        require(voter[msg.sender].isRegistred, "Vous n'etes pas enregistre dans la whitelist.");
        return voter[_address].votedProposalId;
    }

}