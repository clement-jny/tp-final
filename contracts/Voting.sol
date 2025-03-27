// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
	// =============================================================
    //                         STRUCT
    // =============================================================
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    struct Proposal {
        string description;
        uint voteCount;
    }


	// =============================================================
    //                         ENUM
    // =============================================================
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }


    // =============================================================
    //                         MAPPING
    // =============================================================
    // Liste blanche d'électeurs identifiés
    mapping (address => Voter) private whitelist;
    // Liste de propositions
    mapping (uint => Proposal) private proposals;


    // =============================================================
    //                         STATE VARIABLES
    // =============================================================
	// Identifiant de la proposition gagnante
	uint public winningProposalId;
	// Statut actuel du workflow
	WorkflowStatus private currentWorkflowStatus;
	// Liste des ids des propositions
	uint[] private proposalIds;


    // =============================================================
    //                         EVENTS
    // =============================================================
	// Enregistrement d'un votant
    event VoterRegistered(address voterAddress);
	// Changement de statut du workflow
    event WorkflowStatusChange(WorkflowStatus previousState, WorkflowStatus newStatus);
	// Enregistrement d'une proposition
    event ProposalRegistered(uint proposalId);
	// Vote
    event Voted(address voter, uint proposalId);


    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================
	// Constructeur avec l'adresse du propriétaire
    constructor() Ownable(msg.sender) {}


    // =============================================================
    //                         MODIFIER
    // =============================================================
	// Vérifie que l'adresse n'est pas 0
    modifier notTashAddr(address _address) {
        require(_address != address(0), "Can not add address 0!");
        _;
    }
	// Vérifie que l'adresse est enregistrée
    modifier isRegistered(address _voter) {
        require(whitelist[_voter].isRegistered, "Voter not registered");
        _;
    }


	// =============================================================
    //                         FUNCTIONS
    // =============================================================
	/**
	 * @notice Récupère le statut du workflow.
	 * @return Le statut actuel du workflow.
	 */
    function getWorkflowStatus() private view returns (WorkflowStatus) { return currentWorkflowStatus; }
	/**
	 * @notice Change le statut du workflow.
	 * @param _newWorkflowStatus Le nouveau statut du workflow.
	 */
    function changeWorkflowStatus(WorkflowStatus _newWorkflowStatus) private {
		currentWorkflowStatus = _newWorkflowStatus;
		emit WorkflowStatusChange(currentWorkflowStatus, _newWorkflowStatus);
    }
    /**
    * @notice Change le statut du workflow au statut suivant.
    * @dev Seul le propriétaire peut appeler cette fonction.
    */
    function changeToNextWorkflowStatus() public onlyOwner {
        WorkflowStatus currentStatus = getWorkflowStatus();

        if (currentStatus == WorkflowStatus.VotingSessionEnded) {
            changeWorkflowStatus(WorkflowStatus.VotesTallied);
            tallyVotes();
            return;
        }

        require(currentStatus != WorkflowStatus.VotesTallied, "Workflow already completed");

        changeWorkflowStatus(WorkflowStatus(uint8(currentStatus) + 1));
    }

	/**
    * @notice Récupère toutes les propositions enregistrées.
    * @return proposalsArray Un tableau contenant toutes les propositions.
    */
    function getProposals() public view returns (uint[] memory, Proposal[] memory) {
        uint length = proposalIds.length;
        uint[] memory ids = new uint[](length);
        Proposal[] memory proposalsArray = new Proposal[](length);

        for (uint i = 0; i < length; i++) {
            uint proposalId = proposalIds[i];
            ids[i] = proposalId;
            proposalsArray[i] = proposals[proposalId];
        }

        return (ids, proposalsArray);
    }

    /**
     * @notice Ajoute un votant à la liste blanche.
     * @dev Seul l'owner peut appeler cette fonction. L'adresse ne doit pas être déjà enregistrée.
     * @dev L'adresse ne peut être 0.
     * @param _voter L'adresse du votant à enregistrer.
     */
    function addToWhitelist(address _voter) public onlyOwner notTashAddr(_voter) {
		require(getWorkflowStatus() != WorkflowStatus.ProposalsRegistrationStarted, "Proposal sessions started");
		require(getWorkflowStatus() != WorkflowStatus.VotingSessionStarted, "Vote sessions started");

        require(!whitelist[_voter].isRegistered, "Voter already registered");

		changeWorkflowStatus(WorkflowStatus.RegisteringVoters);

        whitelist[_voter] = Voter({
            isRegistered: true,
            hasVoted: false,
            votedProposalId: 0
        });

        emit VoterRegistered(_voter);
    }

	/**
	* @notice Vérifie si une proposition est déjà enregistrée.
	* @param _proposalId L'identifiant de la proposition à vérifier.
	* @return `true` si la proposition est déjà enregistrée, sinon `false`.
	*/
	function isProposalRegistered(uint _proposalId) private view returns (bool) {
		for (uint i = 0; i < proposalIds.length; i++) {
			if (proposalIds[i] == _proposalId) {
				return true;
			}
		}
		return false;
	}
	/**
	 * @notice Enregistre une proposition.
	 * @dev La session d'enregistrement des propositions doit être en cours.
	 * @dev La proposition ne doit pas déjà être enregistrée.
	 * @param _proposalId L'identifiant de la proposition.
	 * @param _description La description de la proposition.
	 */
	function registerProposal(uint _proposalId, string calldata _description) public isRegistered(msg.sender) {
		require(getWorkflowStatus() == WorkflowStatus.ProposalsRegistrationStarted, "Proposals registration not started");
        require (!isProposalRegistered(_proposalId), "Proposal already registered");
        
		proposalIds.push(_proposalId);
        proposals[_proposalId] = Proposal({
            description: _description,
            voteCount: 0
        });

        emit ProposalRegistered(_proposalId);
	}


    /**
    * @notice Enregistre le vote d'un électeur pour une proposition.
    * @dev L'électeur doit être enregistré et n'avoir pas encore voté.
    * @param _proposalId L'identifiant de la proposition choisie.
    */
	function vote(uint _proposalId) public isRegistered(msg.sender) {
		require(getWorkflowStatus() == WorkflowStatus.VotingSessionStarted, "Voting session not started");
		require(!whitelist[msg.sender].hasVoted, "Voter already voted");

		whitelist[msg.sender].hasVoted = true;
		whitelist[msg.sender].votedProposalId = _proposalId;

        proposals[_proposalId].voteCount++;

		emit Voted(msg.sender, _proposalId);
	}


    /**
    * @notice Compte les votes et détermine la proposition gagnante.
    * @dev Fonction privée appelée automatiquement à la fin du vote.
    */
	function tallyVotes() private {
		uint winningVoteCount = 0;
		for (uint i = 0; i < proposalIds.length; i++) {
			if (proposals[i].voteCount > winningVoteCount) {
				winningVoteCount = proposals[i].voteCount;
				winningProposalId = i;
			}
		}
	}

    /**
    * @notice Récupère la description de la proposition gagnante.
    * @dev Seul le propriétaire peut accéder à cette information.
    * @return La description de la proposition ayant reçu le plus de votes.
    */
    function getWinner() public view onlyOwner returns (string memory) {
        return proposals[winningProposalId].description;
    }
}
