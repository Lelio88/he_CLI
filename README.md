# 🚀 HE CLI - Heian Enterprise Command Line Interface

Un outil en ligne de commande puissant et simple pour gérer vos projets GitHub avec style !

## ✨ Fonctionnalités

- 🔨 **firstpush** - Créez un nouveau repository GitHub et faites votre premier push en une seule commande
- 📤 **startpush** - Poussez votre code vers un repository GitHub existant
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

## 🎯 Utilisation

### `he firstpush` - Créer un nouveau repository

Créez un nouveau repository GitHub et faites votre premier push automatiquement :

```bash
# Mode interactif (demande si public ou privé)
he firstpush mon-nouveau-projet

# Créer un repository public
he firstpush mon-projet-public -pu

# Créer un repository privé
he firstpush mon-projet-prive -pr
```

**Ce que fait cette commande :**
1. ✅ Vérifie que GitHub CLI est installé (l'installe si nécessaire)
2. ✅ Vérifie votre authentification GitHub
3. ✅ Vérifie que le nom du repository est disponible
4. ✅ Initialise Git localement
5. ✅ Crée le commit initial
6. ✅ Crée le repository sur GitHub
7. ✅ Fait le premier push

### `he startpush` - Pousser vers un repo existant

Poussez votre code vers un repository GitHub existant :

```bash
he startpush https://github.com/username/repo.git
```

**Ce que fait cette commande :**
1. ✅ Initialise Git si nécessaire
2. ✅ Configure le remote origin
3. ✅ Ajoute tous les fichiers
4. ✅ Crée le commit "initial commit"
5. ✅ Pousse vers la branche main

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
├── firstpush.ps1       # Script de création de repo
├── startpush.ps1       # Script de push vers repo existant
├── heian.ps1          # Script d'affichage du logo
├── help.ps1           # Script d'aide
└── README.md          # Ce fichier
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
he firstpush mon-premier-repo -pu
```

## 📝 Licence

MIT License - Utilisez librement !

## 👤 Auteur

**Lelio88** - [GitHub](https://github.com/Lelio88)

## 🌟 Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

---

Made with ❤️ by Lelio B