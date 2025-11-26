# Nom du projet

Application iOS pour gérer des médicaments.

## Table des matières

* [Installation](#installation)
* [Usage](#usage)
* [Fonctionnalités](#fonctionnalités)
* [Contribuer](#contribuer)

## Installation

Ce projet nécessite un compte Firebase pour fonctionner. Comme le fichier `GoogleInfoService.plist` n'est pas inclus dans ce dépôt pour des raisons de sécurité, voici comment configurer le projet :

1. Crée un compte sur [Firebase](https://firebase.google.com/).
2. Crée un nouveau projet et configure une application iOS dans Firebase.
3. Télécharge le fichier `GoogleInfoService.plist` fourni par Firebase.
4. Place ce fichier à la racine de ton projet Xcode.
5. Installe les dépendances du projet (Swift Package Manager).
6. Ouvre le projet dans Xcode et compile-le.

```bash
git clone https://github.com/ton-utilisateur/ton-projet.git
cd ton-projet
# installer les dépendances ici 
```

## Usage

L'application permet de gérer des médicaments.

## Fonctionnalités

* Créer un médicament avec nom, aisle et stock
* Modifier ou supprimer un médicament existant
* Filtrer la liste par nom et/ou trier par nom ou stock

## Contribuer

Si quelqu’un veut contribuer :

1. Fork le projet
2. Crée une branche
3. Propose une pull request

