# Smart Contract Voting System

Un système de vote décentralisé implémenté en Solidity utilisant le framework Hardhat.

## Description

Ce smart contract permet de gérer un système de vote complet avec différentes phases et restrictions.

## Structure du Contrat

### Structures de Données

- `Voter`: Structure représentant un électeur

  - `isRegistered`: Boolean indiquant si l'électeur est enregistré
  - `hasVoted`: Boolean indiquant si l'électeur a voté
  - `votedProposalId`: ID de la proposition pour laquelle l'électeur a voté

- `Proposal`: Structure représentant une proposition

  - `description`: Description de la proposition
  - `voteCount`: Nombre de votes reçus

### Workflow

Le système suit un workflow précis avec les états suivants:

1. RegisteringVoters
2. ProposalsRegistrationStarted
3. ProposalsRegistrationEnded
4. VotingSessionStarted
5. VotingSessionEnded
6. VotesTallied

## Fonctionnalités Principales

### Gestion des Électeurs

- `addToWhitelist(address _voter)`: Ajoute un électeur à la liste blanche
  - Accessible uniquement par le propriétaire
  - Vérifie que l'adresse n'est pas nulle
  - Vérifie que l'électeur n'est pas déjà enregistré

### Gestion des Propositions

- `registerProposal(uint _proposalId, string _description)`: Enregistre une nouvelle proposition

  - Accessible uniquement aux électeurs enregistrés
  - Vérifie que la session d'enregistrement est en cours
  - Vérifie que la proposition n'existe pas déjà

- `getProposals()`: Récupère toutes les propositions enregistrées

### Gestion des Votes

- `vote(uint _proposalId)`: Permet à un électeur de voter
  - Accessible uniquement aux électeurs enregistrés
  - Vérifie que la session de vote est en cours
  - Vérifie que l'électeur n'a pas déjà voté

### Administration du Workflow

- `changeToNextWorkflowStatus()`: Passe à la phase suivante du processus
  - Accessible uniquement par le propriétaire
  - Gère automatiquement la transition entre les phases

### Comptabilisation des Votes

- `tallyVotes()`: Compte les votes et détermine le gagnant
  - Exécuté automatiquement à la fin du processus
- `getWinner()`: Retourne la description de la proposition gagnante
  - Accessible uniquement par le propriétaire

## Events

Le contrat émet les événements suivants:

- `VoterRegistered`: Lors de l'enregistrement d'un nouvel électeur
- `WorkflowStatusChange`: Lors du changement de phase
- `ProposalRegistered`: Lors de l'enregistrement d'une nouvelle proposition
- `Voted`: Lors d'un vote

## Sécurité

- Utilisation du pattern Ownable d'OpenZeppelin
- Vérifications des conditions d'accès via des modifiers
- Contrôles d'état pour chaque action
- Protection contre les adresses nulles

## Comment utiliser

```shell
npx hardhat node

# Compiler le contrat
npx hardhat compile

# Déployer le contrat
npx hardhat ignition deploy ./ignition/modules/Voting.ts

# Tester le contrat
npx hardhat test
```
