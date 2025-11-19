# 🚀 HE CLI - Heian Enterprise Command Line Interface

Un outil CLI puissant pour gérer vos projets Git et GitHub avec simplicité. Créez des repos, synchronisez votre code, gérez vos commits et créez des backups en une seule commande !

## ✨ Fonctionnalités

### 📦 Gestion des repositories
- 🔨 **createrepo** - Créez un nouveau repository GitHub et faites votre premier push en une seule commande
- ⚡ **fastpush** - Push rapide avec message de commit personnalisable

### 🔄 Synchronisation et commits
- 🔄 **update** - Synchronisation automatique complète (commit + pull + push)
- 📊 **logcommit** - Affichez l'historique des commits avec un graphe ASCII élégant
- ⏮️ **rollback** - Annulez le dernier commit en gardant les fichiers modifiés

### 💾 Sauvegarde
- 💾 **backup** - Créez une archive ZIP complète du projet avec numérotation automatique

### 🎨 Utilitaires
- 🔄 **selfupdate** - Mettez à jour HE CLI vers la dernière version automatiquement
- 🎨 **heian** - Affichez le logo Heian Enterprise avec style
- ❓ **help** - Obtenez de l'aide sur toutes les commandes disponibles

## 📦 Installation

### Installation automatique (recommandée)

**Option 1 : PowerShell (une ligne)**

Ouvrez PowerShell et exécutez :

```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex
```

**Option 2 : Fichier batch**

1. Téléchargez le fichier [install.bat](https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.bat)
2. Double-cliquez dessus pour lancer l'installation

**Après l'installation :**
- Redémarrez votre terminal
- Tapez `he help` pour commencer !

### Installation manuelle

1. Clonez ce repository :
```bash
git clone https://github.com/Lelio88/he_CLI.git
```

2. Copiez les fichiers dans `C:\Users\<VotreNom>\he-tools\`

3. Ajoutez `C:\Users\<VotreNom>\he-tools\` au PATH de votre système :
   - Ouvrez les Paramètres système avancés
   - Variables d'environnement
   - Dans "Variables système", modifiez `Path`
   - Ajoutez `C:\Users\<VotreNom>\he-tools\`

4. Redémarrez votre terminal

## 🔄 Mise à jour

Pour mettre à jour HE CLI vers la dernière version, utilisez simplement :

```bash
he selfupdate
```

Ou alternativement, réexécutez la commande d'installation :

```powershell
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex
```

**Pas besoin de redémarrer le terminal après une mise à jour !**

## 🎯 Utilisation

### `he createrepo` - Créer un nouveau repository

Créez un nouveau repository GitHub et faites votre premier push automatiquement :

```bash
# Mode interactif (demande si public ou privé)
he createrepo mon-nouveau-projet

# Créer un repository public
he createrepo mon-projet-public -pu

# Créer un repository privé
he createrepo mon-projet-prive -pr
```

**Ce que fait cette commande :**
1. ✅ Vérifie que GitHub CLI est installé (l'installe si nécessaire)
2. ✅ Vérifie votre authentification GitHub
3. ✅ Vérifie que le nom du repository est disponible
4. ✅ Initialise Git localement
5. ✅ Crée le commit initial
6. ✅ Crée le repository sur GitHub
7. ✅ Fait le premier push

### `he fastpush` - Push rapide avec message personnalisé

Poussez rapidement vers un repository avec un message de commit personnalisé :

```bash
# Mode interactif (demande le message)
he fastpush https://github.com/username/repo.git -m

# Avec message direct
he fastpush https://github.com/username/repo.git -m "Mon message de commit"

# Sans message (utilise "initial commit" par défaut)
he fastpush https://github.com/username/repo.git
```

**Ce que fait cette commande :**
1. ✅ Initialise Git si nécessaire
2. ✅ Configure le remote origin
3. ✅ Ajoute tous les fichiers
4. ✅ Crée le commit avec votre message
5. ✅ Pousse vers la branche main

### `he update` - Synchronisation automatique

Synchronisez automatiquement votre projet avec GitHub (commit + pull + push) :

```bash
# Mode interactif (demande le message de commit)
he update

# Avec message de commit direct
he update "Ajout de nouvelles fonctionnalités"
```

**Ce que fait cette commande :**
1. ✅ Vérifie les fichiers modifiés
2. ✅ Ajoute et commit les changements
3. ✅ Pull les derniers changements depuis GitHub
4. ✅ Push les commits vers GitHub
5. ✅ Gère automatiquement les conflits éventuels

### `he logcommit` - Historique des commits

Affichez l'historique de vos commits avec un graphe visuel :

```bash
# Afficher les 20 derniers commits (par défaut)
he logcommit

# Afficher les 50 derniers commits
he logcommit 50

# Afficher tous les commits
he logcommit 0
```

**Affiche :**
- 📊 Graphe ASCII des branches et commits
- 📈 Statistiques de la branche actuelle
- 📝 Détails du dernier commit
- 🔢 Nombre total de commits

### `he rollback` - Annuler le dernier commit

Annulez le dernier commit tout en gardant vos fichiers modifiés :

```bash
# Mode interactif (demande confirmation)
he rollback

# Mode automatique (sans confirmation)
he rollback -d
```

**Ce que fait cette commande :**
1. ✅ Affiche le commit qui sera annulé
2. ✅ Demande confirmation (sauf avec -d)
3. ✅ Annule le commit (git reset --soft HEAD~1)
4. ✅ Garde les fichiers en staging
5. ✅ Propose de modifier l'espace distant GitHub (avec --force)

**⚠️ Note :** Le flag `-d` accepte automatiquement toutes les confirmations.

### `he backup` - Sauvegarde du projet

Créez une archive ZIP complète de votre projet :

```bash
he backup
```

**Ce que fait cette commande :**
1. ✅ Crée un dossier `backups/` dans votre projet
2. ✅ Génère un fichier ZIP avec date, heure et numéro
3. ✅ Exclut automatiquement `.git/`, `node_modules/`, `backups/`, etc.
4. ✅ Affiche la taille et le nombre de fichiers sauvegardés
5. ✅ Numérote automatiquement les backups (#1, #2, #3...)

**Format du nom :** `projet_2025-01-19_14-30-45_#1.zip`

### `he selfupdate` - Mettre à jour HE CLI

Mettez à jour HE CLI vers la dernière version disponible :

```bash
he selfupdate
```

**Ce que fait cette commande :**
1. ✅ Télécharge la dernière version depuis GitHub
2. ✅ Remplace tous les fichiers par les versions les plus récentes
3. ✅ Affiche les nouvelles fonctionnalités disponibles
4. ✅ Pas besoin de redémarrer le terminal

**💡 Astuce :** Exécutez `he selfupdate` régulièrement pour bénéficier des dernières améliorations !

### `he heian` - Logo stylé

Affichez le logo Heian Enterprise dans votre terminal :

```bash
he heian
```

### `he help` - Aide

Obtenez de l'aide sur toutes les commandes :

```bash
he help
```

## 🛠️ Structure du projet

```
he_CLI/
├── install.ps1         # Script d'installation PowerShell
├── install.bat         # Script d'installation batch
├── he.cmd              # Point d'entrée de la commande
├── main.ps1            # Router principal
├── createrepo.ps1      # Script de création de repo
├── fastpush.ps1        # Script de push rapide avec message
├── update.ps1          # Script de synchronisation automatique
├── logcommit.ps1       # Script d'affichage de l'historique
├── rollback.ps1        # Script d'annulation de commit
├── backup.ps1          # Script de sauvegarde
├── selfupdate.ps1      # Script de mise à jour
├── heian.ps1           # Script d'affichage du logo
├── help.ps1            # Script d'aide
└── README.md           # Ce fichier
```

## 📚 Workflows recommandés

### Workflow quotidien

```bash
# 1. Travaillez sur votre code...

# 2. Synchronisez avec GitHub
he update "Description de vos modifications"

# 3. Créez une sauvegarde locale (optionnel)
he backup
```

### Workflow de création de projet

```bash
# 1. Créez votre projet localement
mkdir mon-projet
cd mon-projet

# 2. Créez le repository GitHub
he createrepo mon-projet -pu

# 3. Travaillez sur votre code...

# 4. Synchronisez régulièrement
he update "Premiers changements"
```

### Workflow de correction d'erreur

```bash
# 1. Vous avez fait un mauvais commit ? Annulez-le
he rollback

# 2. Modifiez vos fichiers

# 3. Recommitez correctement
he update "Correction du bug"
```

### Workflow de maintenance

```bash
# 1. Mettez à jour HE CLI régulièrement
he selfupdate

# 2. Créez des backups avant les grosses modifications
he backup

# 3. Vérifiez l'historique si besoin
he logcommit
```

## 🐛 Résolution des problèmes

### Les caractères accentués ne s'affichent pas correctement

Assurez-vous que vos fichiers PowerShell sont encodés en UTF-8 with BOM.

### "Le terme 'he' n'est pas reconnu"

Vérifiez que `C:\Users\<VotreNom>\he-tools\` est bien dans votre PATH et redémarrez votre terminal.

### Erreur lors de la création du repository

Vérifiez que :
- Vous êtes authentifié sur GitHub CLI (`gh auth status`)
- Le nom du repository n'existe pas déjà
- Vous avez une connexion Internet

### Conflit lors du update

Si un conflit se produit lors du `he update` :
1. Éditez les fichiers en conflit
2. `git add .`
3. `git commit -m "resolve conflicts"`
4. `he update`

### La mise à jour échoue

Si `he selfupdate` échoue :
1. Vérifiez votre connexion Internet
2. Essayez manuellement : `irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex`
3. Ouvrez une issue sur GitHub avec le message d'erreur

### L'installation échoue

Si l'installation automatique échoue :
1. Vérifiez votre connexion Internet
2. Essayez l'installation manuelle
3. Ouvrez une issue sur GitHub avec le message d'erreur

## 🚀 Quick Start

```bash
# Installer HE CLI
irm https://raw.githubusercontent.com/Lelio88/he_CLI/main/install.ps1 | iex

# Redémarrer le terminal, puis :
he help

# Créer votre premier projet
cd mon-projet
he createrepo mon-premier-repo -pu

# Travailler et synchroniser
# ... modifier vos fichiers ...
he update "Mes modifications"

# Créer une sauvegarde
he backup

# Voir l'historique
he logcommit

# Mettre à jour HE CLI
he selfupdate
```

## 💡 Astuces et conseils

- 🔄 Utilisez `he update` régulièrement pour rester synchronisé
- 💾 Créez des backups avant les grosses modifications avec `he backup`
- 📊 Vérifiez l'historique avec `he logcommit` avant de rollback
- ⚡ Utilisez `he fastpush` pour les pushs rapides sans configuration
- 🔒 Le flag `-d` sur `he rollback` évite les confirmations
- 🆕 Exécutez `he selfupdate` régulièrement pour avoir les dernières fonctionnalités

## 📝 Licence

MIT License - Utilisez librement !

## 👤 Auteur

**Lelio88** - [GitHub](https://github.com/Lelio88)

## 🌟 Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## 📋 Changelog

### Version actuelle
- ✨ Ajout de `he selfupdate` - Mise à jour automatique
- ✨ Ajout de `he backup` - Sauvegarde en ZIP avec numérotation
- ✨ Ajout de `he createrepo` - Création de repository améliorée
- ✨ Ajout de `he fastpush` - Push rapide avec message personnalisé
- ✨ Ajout de `he logcommit` - Historique avec graphe ASCII
- ✨ Ajout de `he rollback` - Annulation de commit
- ✨ Ajout de `he update` - Synchronisation complète automatique

---

Made with ❤️ by Lelio B