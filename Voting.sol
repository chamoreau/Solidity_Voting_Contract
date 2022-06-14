pragma solidity 0.8.14;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/* Charles MOREAU -----Promo Ropsten */
contract Voting is Ownable {
    

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    // Declarations

    mapping(address=> Voter) private _register;
    uint public winningProposalId;
    Proposal[] public proposals;
    WorkflowStatus public currentStatus;
    address[] private StoreAddress;
    bool public exaequo;
    
 

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    // Init

    constructor() public {    
        currentStatus = WorkflowStatus.RegisteringVoters;
        exaequo=false;
    } 

    //functions

    /* Register new voters */
    function register(address _voterAddress) public onlyOwner {
      require(_register[_voterAddress].isRegistered==false,"This voter's address is already registered !");
      _register[_voterAddress].isRegistered = true;
      StoreAddress.push(_voterAddress);
      emit VoterRegistered(_voterAddress);
    }

    /* Allows the contract owner to change the current workflow status */
    function ChangeStatus(uint newStatus) public onlyOwner{
        emit WorkflowStatusChange(WorkflowStatus(currentStatus), WorkflowStatus(newStatus));
        currentStatus = WorkflowStatus(newStatus);
    }

    /* Allows registered voters to submit proposals to a vote */
    function setProposal(string memory _description) public {
        require(_register[msg.sender].isRegistered == true , "You aren't registered");
        require(bytes(_description).length != 0,"Proposal empty");
        require(currentStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals session not started");

        proposals.push(Proposal(_description,0));
        uint proposalId = proposals.length -1;
        emit ProposalRegistered(proposalId);
    }

    /* Allows registered voters to submit proposals to a vote */
    function Vote(uint _proposalId) public {
        require(_register[msg.sender].isRegistered, "You are not registered");
        require(currentStatus == WorkflowStatus.VotingSessionStarted, "Voting session hasn't started yet !");
        require(_register[msg.sender].hasVoted==false, "You've already voted");            
        
        _register[msg.sender].hasVoted = true;
        _register[msg.sender].votedProposalId = _proposalId;
        
        proposals[_proposalId].voteCount++;

        emit Voted (msg.sender, _proposalId);
    }

    /* Returns a voter's description with his address as input */
    function getVoter(address _voterAddress) public view returns ( bool registered, bool _hasVoted, uint VotedProposal) {
        return(_register[_voterAddress].isRegistered,_register[_voterAddress].hasVoted,_register[_voterAddress].votedProposalId);
    }
  
    /* Searches for the highest voted proposal */
    function countVotes() public onlyOwner {
        require(currentStatus == WorkflowStatus.VotingSessionEnded,"Voting sessions hasn't ended yet");
        uint index=0;
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
            else if (proposals[i].voteCount == winningVoteCount)
            {
                index=i;
            }
        }
        if (proposals[index].voteCount==winningVoteCount)
        {
            exaequo=true;
        }
        emit WorkflowStatusChange(WorkflowStatus(currentStatus), WorkflowStatus(WorkflowStatus.VotesTallied));
        currentStatus = WorkflowStatus.VotesTallied;
    }
    
    /* Returns the winning proposal description */
    function getWinningProposal() public view returns (string memory proposaldescription) {
        require(currentStatus == WorkflowStatus.VotesTallied,"Votes have not been counted yet");
        require(exaequo==false,"Il y a plusieurs propositions exaequo");
        return proposals[winningProposalId].description;
    }

    /*Resets all the data entered previously*/
    function ResetAll() public onlyOwner{
        delete(proposals);
        delete(winningProposalId);
        exaequo=false;
        for(uint i=0; i<StoreAddress.length; i++) {
                delete(_register[StoreAddress[i]]);
        }
        delete(StoreAddress);

        emit WorkflowStatusChange(WorkflowStatus(currentStatus), WorkflowStatus(WorkflowStatus.RegisteringVoters));
        currentStatus = WorkflowStatus.RegisteringVoters;
    }

    
}