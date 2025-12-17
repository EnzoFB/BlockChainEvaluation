# 🗳️ SimpleVotingSystem - Blockchain Voting System

Système de vote décentralisé avec gestion de workflow, financement de candidats et NFT de vote développé avec Solidity et Foundry.

## 📋 Description du Projet

Ce projet implémente un système de vote complet sur la blockchain Ethereum avec les fonctionnalités suivantes :

### 🎯 Fonctionnalités Principales

1. **Gestion des Rôles** (OpenZeppelin AccessControl)
   - `ADMIN_ROLE` : Gestion du système et du workflow
   - `FOUNDER_ROLE` : Financement des candidats
   - `MINTER_ROLE` : Mint des NFT de vote

2. **Workflow en 4 Phases**
   - `REGISTER_CANDIDATES` : Enregistrement des candidats par les admins
   - `FOUND_CANDIDATES` : Financement des candidats par les founders
   - `VOTE` : Période de vote (ouverte 1h après activation)
   - `COMPLETED` : Fin du vote et désignation du vainqueur

3. **NFT Anti-Double Vote**
   - Chaque votant reçoit un NFT après avoir voté
   - Impossible de voter si on possède déjà un NFT
   - Standard ERC721

4. **Financement des Candidats**
   - Les founders peuvent envoyer des ETH aux candidats
   - Uniquement pendant la phase FOUND_CANDIDATES

5. **Désignation du Vainqueur**
   - Fonction pour obtenir le candidat avec le plus de votes
   - Accessible uniquement en phase COMPLETED

## 🏗️ Architecture

```
src/
├── SimpleVotingSystem.sol   # Contrat principal de vote
└── SimpleVotingNFT.sol       # Contrat NFT ERC721

test/
├── SimpleVotingSystem.t.sol  # Tests du système (28 tests)
└── SimpleVotingNFT.t.sol      # Tests du NFT (11 tests)

script/
└── DeployVotingSystem.s.sol  # Script de déploiement
```

## 🧪 Tests Unitaires

Le projet contient **39 tests unitaires** couvrant tous les aspects du système :

### Tests SimpleVotingNFT (11 tests)
- Déploiement et initialisation
- Gestion des rôles (MINTER, ADMIN)
- Fonctions de mint
- Vérifications de balance
- Support des interfaces ERC721 et AccessControl

### Tests SimpleVotingSystem (28 tests)
- Déploiement et configuration
- Gestion des rôles (ADMIN, FOUNDER)
- Workflow et transitions de phase
- Enregistrement et validation des candidats
- Système de vote avec délai de 1 heure
- Financement des candidats
- Désignation du vainqueur
- Test d'intégration complet

### Exécuter les Tests

```bash
# Tous les tests
forge test

# Tests avec verbosité
forge test -vv

# Tests avec traces
forge test -vvv

# Test spécifique
forge test --match-test test_Vote

# Rapport de couverture
forge coverage

# Rapport de gaz
forge test --gas-report
```

## 📦 Installation

### Prérequis
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation des Dépendances

```bash
# Cloner le projet
git clone <votre-repo>
cd BlockChainEvaluation

# Installer les dépendances
forge install

# Compiler les contrats
forge build
```

## 🚀 Déploiement sur Sepolia

### 🔧 Prérequis

1. **Obtenir des ETH Sepolia** (testnet)
   - Faucet Alchemy: https://www.alchemy.com/faucets/ethereum-sepolia
   - Faucet Infura: https://www.infura.io/faucet/sepolia
   - Faucet QuickNode: https://faucet.quicknode.com/ethereum/sepolia

2. **Obtenir une clé API RPC**
   - Alchemy: https://www.alchemy.com/
   - Infura: https://www.infura.io/
   - Ou utiliser une RPC publique (moins fiable)

3. **Obtenir une clé API Etherscan** (optionnel, pour vérifier le contrat)
   - https://etherscan.io/apis

### ⚙️ Configuration

1. **Copier le fichier d'exemple**
   ```bash
   cp .env.example .env
   ```

2. **Éditer le fichier .env**
   - Ajouter votre clé privée (sans le préfixe 0x)
   - Ajouter l'URL RPC Sepolia
   - Ajouter la clé API Etherscan (optionnel)

   ⚠️ **ATTENTION**: Ne commitez JAMAIS le fichier .env !

### 📤 Déploiement

#### 1. Tester le déploiement en local (simulation)
```bash
forge script script/DeployVotingSystem.s.sol:DeployVotingSystem --rpc-url sepolia
```

#### 2. Déployer sur Sepolia avec vérification
```bash
forge script script/DeployVotingSystem.s.sol:DeployVotingSystem \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

Options:
- `--broadcast`: Envoie réellement la transaction
- `--verify`: Vérifie le contrat sur Etherscan
- `-vvvv`: Mode verbeux pour voir tous les détails

#### 3. Déployer sans vérification
```bash
forge script script/DeployVotingSystem.s.sol:DeployVotingSystem \
  --rpc-url sepolia \
  --broadcast \
  -vvvv
```

### 📝 Après le Déploiement

Les adresses des contrats déployés seront affichées dans le terminal et sauvegardées dans :
```
broadcast/DeployVotingSystem.s.sol/11155111/run-latest.json
```

Vous pouvez vérifier vos contrats manuellement sur Etherscan si nécessaire :
```bash
forge verify-contract <ADRESSE_CONTRAT> <NOM_CONTRAT> \
  --chain sepolia \
  --etherscan-api-key ${ETHERSCAN_API_KEY}
```

Exemple:
```bash
forge verify-contract 0x123... SimpleVotingNFT --chain sepolia
forge verify-contract 0x456... SimpleVotingSystem --chain sepolia --constructor-args $(cast abi-encode "constructor(address)" 0x123...)
```

### 🔍 Vérifier le Déploiement

1. Visitez Sepolia Etherscan: https://sepolia.etherscan.io/
2. Recherchez vos adresses de contrats
3. Vérifiez les transactions de déploiement

## 🌐 Déploiement sur Sepolia Testnet

### Contrats Déployés

| Contrat | Adresse | Transaction de Déploiement |
|---------|---------|-------------|
| SimpleVotingNFT | `0x9287c061c41013F3855Bd2dc8fe48dF2d999B74a` | [Voir sur Etherscan](https://sepolia.etherscan.io/tx/0x69e49f91cfb11ca2aed032f7a5bfda55d02b06647ad2671a9326098a2cdb5119) |
| SimpleVotingSystem | `0x2dF9362667B0500F48B9EDC91Eb00c7153A370cB` | [Voir sur Etherscan](https://sepolia.etherscan.io/tx/0x2c2693434323f5b303a920c78c93855234b7d7e992589c2a40ea05dc375c132b) |

### Interactions de Test sur le Réseau

Exemples de transactions effectuées sur le testnet Sepolia :

| Action | Transaction |
|--------|-------------|
| Ajout de candidat "Alice" | [0xf8bbe7baef4e5beb73e51b030eef1fdd0dc2d836dfb7afdf624f95be3f714c51](https://sepolia.etherscan.io/tx/0xf8bbe7baef4e5beb73e51b030eef1fdd0dc2d836dfb7afdf624f95be3f714c51) |
| Ajout de candidat "Bob" | [0xd1ee2fcb593d74d3042edb12a04110ed07dfccb18edc724996daebf5bee15619](https://sepolia.etherscan.io/tx/0xd1ee2fcb593d74d3042edb12a04110ed07dfccb18edc724996daebf5bee15619) |
| Ajout de candidat "Charlie" | [0x1aaddff7868e890355e64080fb66a7e07b877209138c7b89c6ac293ee20f90f7](https://sepolia.etherscan.io/tx/0x1aaddff7868e890355e64080fb66a7e07b877209138c7b89c6ac293ee20f90f7) |
| Attribution du rôle FOUNDER | [0x0c53f6ff7b8581341170d4c19c12b5d6e7b0ca5f0e80209082e2f90a74243b3e](https://sepolia.etherscan.io/tx/0x0c53f6ff7b8581341170d4c19c12b5d6e7b0ca5f0e80209082e2f90a74243b3e) |
| Attribution du rôle MINTER (lors du déploiement) | [0xd8c80f0d3359c45f466ff49894009a64b59c968f26478814f3088d5d357139db](https://sepolia.etherscan.io/tx/0xd8c80f0d3359c45f466ff49894009a64b59c968f26478814f3088d5d357139db) |

> **Note**: Tous les contrats sont déployés et testés sur Sepolia. Vous pouvez continuer le workflow en changeant les phases et en effectuant des votes.

## 💡 Utilisation

### Commandes Cast Utiles

```bash
# Vérifier votre solde
cast balance <VOTRE_ADRESSE> --rpc-url sepolia

# Obtenir l'adresse depuis la clé privée
cast wallet address <PRIVATE_KEY>

# Voir les détails d'une transaction
cast tx <TX_HASH> --rpc-url sepolia

# Appeler une fonction en lecture
cast call <CONTRACT_ADDRESS> "workflowStatus()(uint8)" --rpc-url sepolia

# Envoyer une transaction
cast send <CONTRACT_ADDRESS> "addCandidate(string)" "Alice" \
  --rpc-url sepolia \
  --private-key ${PRIVATE_KEY}
```

### ⚡ Workflow Complet d'Utilisation

Après le déploiement, voici les étapes pour utiliser le système :

```bash
# 1. Ajouter des candidats (phase REGISTER_CANDIDATES par défaut)
cast send <VOTING_SYSTEM_ADDRESS> "addCandidate(string)" "Alice" --rpc-url sepolia --private-key ${PRIVATE_KEY}
cast send <VOTING_SYSTEM_ADDRESS> "addCandidate(string)" "Bob" --rpc-url sepolia --private-key ${PRIVATE_KEY}

# 2. Passer à la phase FOUND_CANDIDATES (1)
cast send <VOTING_SYSTEM_ADDRESS> "setWorkflowStatus(uint8)" 1 --rpc-url sepolia --private-key ${PRIVATE_KEY}

# 3. Accorder le rôle FOUNDER
cast send <VOTING_SYSTEM_ADDRESS> "grantFounder(address)" <FOUNDER_ADDRESS> --rpc-url sepolia --private-key ${PRIVATE_KEY}

# 4. Financer un candidat
cast send <VOTING_SYSTEM_ADDRESS> "fundCandidate(uint256)" 1 --value 0.1ether --rpc-url sepolia --private-key ${FOUNDER_PRIVATE_KEY}

# 5. Passer à la phase VOTE (2)
cast send <VOTING_SYSTEM_ADDRESS> "setWorkflowStatus(uint8)" 2 --rpc-url sepolia --private-key ${PRIVATE_KEY}

# 6. Attendre 1 heure, puis voter
cast send <VOTING_SYSTEM_ADDRESS> "vote(uint256)" 1 --rpc-url sepolia --private-key ${VOTER_PRIVATE_KEY}

# 7. Passer à la phase COMPLETED (3)
cast send <VOTING_SYSTEM_ADDRESS> "setWorkflowStatus(uint8)" 3 --rpc-url sepolia --private-key ${PRIVATE_KEY}

# 8. Obtenir le vainqueur
cast call <VOTING_SYSTEM_ADDRESS> "getWinner()(uint256,string,uint256)" --rpc-url sepolia
```

## 📊 Résultats des Tests

```
Ran 2 test suites: 39 tests passed, 0 failed, 0 skipped

✅ SimpleVotingNFT.t.sol: 11 passed
✅ SimpleVotingSystem.t.sol: 28 passed
```

## 🛠️ Outils Foundry

### Build

```bash
forge build
```

### Format

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Anvil (Local Network)

```bash
anvil
```

### Aide

```bash
forge --help
anvil --help
cast --help
```

## 📚 Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

## 🔐 Sécurité

- ⚠️ Ne commitez JAMAIS votre fichier `.env` avec de vraies clés privées
- ✅ Le fichier `.gitignore` est configuré pour ignorer `.env`
- ✅ Utilisez uniquement des clés de test sur les testnets
- ✅ Tous les contrats utilisent les libraries sécurisées d'OpenZeppelin

## 📄 License

MIT

## 👤 Auteur

EnzoFB

## 🤝 Contributions

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.
