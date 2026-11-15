# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [한국어](README.ko.md) | [Español](README.es.md) | **Français** | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

Serveur MCP pour la gestion des extensions du Chrome Web Store. Importez, publiez et gérez vos extensions Chrome directement depuis Claude Code ou n'importe quel client MCP.

> Fork de [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp), mis à jour pour l'**API V2** du Chrome Web Store : authentification par compte de service, un flux OAuth fonctionnel (Google a supprimé l'ancien flux `oob`) et le dernier SDK MCP.

## Quand l'utiliser

Utilisez ce MCP lorsque vous devez :

- **« Importer une nouvelle version de mon extension Chrome »** — générez votre ZIP et utilisez l'outil `upload` pour l'envoyer comme brouillon
- **« Publier mon extension sur le Chrome Web Store »** — utilisez `publish` pour la soumettre à examen et la mettre en ligne
- **« Vérifier l'état d'examen de mon extension »** — utilisez `status` pour consulter l'état de l'examen, la version et le pourcentage de déploiement
- **« Importer et publier en une seule étape »** — utilisez `submit` pour exécuter upload → publish → status en un seul appel
- **« Annuler une soumission en attente »** — utilisez `cancel` pour retirer une soumission en cours d'examen
- **« Mettre en place un déploiement progressif de mon extension »** — utilisez `publish` avec `deployPercentage`, puis `deploy-percentage` pour monter en charge
- **« La nouvelle version est défectueuse, je veux revenir en arrière »** — utilisez `rollback` (validez d'abord avec `validateOnly=true`)
- **« Afficher mes derniers avis / ma note »** — utilisez `reviews` et `rating-summary`
- **« Combien d'installations et d'utilisateurs actifs ai-je eus le mois dernier ? »** — utilisez `metrics`

## Outils

| Outil | Description |
|---|---|
| `upload` | Importe un fichier ZIP dans le Chrome Web Store (met à jour le brouillon d'un élément existant) |
| `publish` | Publie une extension avec déploiement progressif, type de publication et omission de l'examen en option |
| `status` | Récupère l'état actuel, y compris l'état de l'examen, le pourcentage de déploiement et la version |
| `cancel` | Annule une soumission en attente |
| `deploy-percentage` | Définit le pourcentage de déploiement progressif (0-100, doit dépasser la cible actuelle) |
| `get`, `update-metadata` | Anciens outils de métadonnées ; bloqués par le serveur après sa date limite v1 (voir ci-dessous) |
| `submit` | Tout-en-un : exécute upload → publish → status en un seul appel (avec vérification préalable de l'existence et erreurs lisibles) |
| `rollback` | Republie une version précédemment publiée sous un nouveau numéro de version supérieur (sans examen ; prend en charge la simulation `validateOnly`) |
| `reviews` | Récupère les avis des utilisateurs avec pagination, tri (`rating`, `create_time desc`) et filtre par note |
| `rating-summary` | Récupère la note moyenne, le nombre de notes et le nombre par étoile |
| `metrics` | Interroge les installations, désinstallations, utilisateurs quotidiens/sur 7 jours, impressions et pages vues sur une période, éventuellement ventilées selon une dimension |

`reviews`, `rating-summary` et `metrics` sont en lecture seule ; ils acceptent aussi des identifiants limités au périmètre `https://www.googleapis.com/auth/chromewebstore.readonly`, mais le serveur demande le périmètre complet `chromewebstore` pour les comptes de service.

> L'API du Chrome Web Store ne peut pas créer d'éléments. Créez un nouvel élément manuellement dans le Developer Dashboard du Chrome Web Store, puis utilisez `upload` / `publish` (ou `submit`) avec son ID d'élément.

## Métadonnées de la fiche

Le serveur bloque `get` et `update-metadata` lorsque son horloge dépasse **2026-10-15 00:00 UTC**, avant d'effectuer toute requête d'API. Ces anciens outils restent visibles lors de la découverte, mais ne peuvent plus être utilisés après cette date limite. Modifiez le texte de la fiche et les autres métadonnées manuellement dans le Developer Dashboard du Chrome Web Store ; ce serveur ne propose ni remplacement des métadonnées en v2 ni automatisation du navigateur.

Utilisez `status` pour l'état de l'examen, la version et les informations de déploiement. Les prompts orientent le travail sur les métadonnées de la fiche vers le Developer Dashboard. La ressource `cws://extensions/{extensionId}` renvoie toujours l'état v2 après la date limite, ignore la requête v1 et signale `metadata.unavailable`.

## Configuration

Installez Node.js **20 ou plus récent** pour utiliser les exemples `npx` ci-dessous, ou installez Bun et remplacez `"command": "npx"` et `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` par `"command": "bunx"` et `"args": ["--bun", "@kagayoi/cws-mcp@latest"]` (équivalent à `bunx --bun @kagayoi/cws-mcp@latest`) pour fonctionner sans Node.js. Aucune des deux options ne nécessite d'installation globale du paquet. Avec `@latest`, chaque lancement exécute la dernière version publiée sur npm.

Si vous avez déjà enregistré le serveur avec une version figée (par exemple `@kagayoi/cws-mcp@2.0.10`) ou sans version (`@kagayoi/cws-mcp`), remplacez l'argument du paquet dans cet enregistrement par `@kagayoi/cws-mcp@latest` ; la mise à jour de ce README ne modifie pas les enregistrements existants, mais après cette modification chaque lancement utilisera automatiquement la dernière version.

Authentifiez-vous **soit** avec un compte de service (recommandé, idéal pour la CI/CD) **soit** avec un jeton d'actualisation OAuth2.

### Option A — Compte de service (recommandé)

1. Dans la [Google Cloud Console](https://console.cloud.google.com/), créez ou sélectionnez un projet et activez la **Chrome Web Store API**.
2. Créez un **compte de service**, puis ajoutez une **clé JSON** (Keys → Add key → Create new key → JSON).
3. Dans le [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **Account**, ajoutez l'adresse e-mail du compte de service pour lui accorder l'accès à l'API de votre compte éditeur.
4. Définissez `CWS_SERVICE_ACCOUNT_KEY` avec le **chemin du fichier de clé JSON** (ou son contenu JSON brut).

Consultez [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts) pour plus de détails.

### Option B — Jeton d'actualisation OAuth2

1. Dans la [Google Cloud Console](https://console.cloud.google.com/), créez ou sélectionnez un projet et activez la **Chrome Web Store API**.
2. Créez des **identifiants OAuth2** de type **Desktop app**. Notez le **Client ID** et le **Client Secret**.
3. Obtenez un jeton d'actualisation à l'aide d'une **redirection loopback**. (L'ancien flux `urn:ietf:wg:oauth:2.0:oob` a été supprimé par Google en 2022 et ne fonctionne plus ; les clients de bureau utilisent désormais `http://localhost`.)

   ```bash
   # 1. Open this URL in a browser and grant access:
   #    https://accounts.google.com/o/oauth2/v2/auth?response_type=code&access_type=offline&prompt=consent&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fchromewebstore&client_id=YOUR_CLIENT_ID&redirect_uri=http://localhost:8080
   #
   # 2. The browser is redirected to http://localhost:8080/?code=AUTH_CODE&...
   #    (no server needed — just copy the `code` value from the address bar).
   #
   # 3. Exchange the code for a refresh token:
   curl -X POST https://oauth2.googleapis.com/token \
     -d "client_id=YOUR_CLIENT_ID" \
     -d "client_secret=YOUR_CLIENT_SECRET" \
     -d "code=YOUR_AUTH_CODE" \
     -d "grant_type=authorization_code" \
     -d "redirect_uri=http://localhost:8080"
   ```

   La réponse contient votre `refresh_token`. Toute redirection `http://localhost[:PORT]` ou `http://127.0.0.1[:PORT]` est acceptée pour les clients de type Desktop app.

### Configurer MCP

Ajoutez la définition de serveur suivante à la configuration de votre client MCP. L'exemple utilise le format `mcpServers` ; utilisez l'emplacement de configuration ou la commande d'ajout de serveur documentés par votre client.

**Via npm avec un compte de service (recommandé) :**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["--yes", "@kagayoi/cws-mcp@latest"],
      "env": {
        "CWS_SERVICE_ACCOUNT_KEY": "/path/to/service-account.json",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

**Via npm avec un jeton d'actualisation OAuth :**

```json
{
  "mcpServers": {
    "cws-mcp": {
      "command": "npx",
      "args": ["--yes", "@kagayoi/cws-mcp@latest"],
      "env": {
        "CWS_CLIENT_ID": "xxxxx.apps.googleusercontent.com",
        "CWS_CLIENT_SECRET": "GOCSPX-xxxxx",
        "CWS_REFRESH_TOKEN": "1//xxxxx",
        "CWS_PUBLISHER_ID": "me",
        "CWS_ITEM_ID": "your-extension-id"
      }
    }
  }
}
```

## Variables d'environnement

Fournissez **soit** une clé de compte de service (Auth A) **soit** le trio d'identifiants du jeton d'actualisation OAuth2 (Auth B).

| Variable | Requise | Description |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | Auth A | Chemin d'un fichier de clé JSON de compte de service, ou la chaîne JSON brute. Prioritaire sur OAuth lorsqu'elle est définie. |
| `CWS_CLIENT_ID` | Auth B | Client ID Google OAuth2 |
| `CWS_CLIENT_SECRET` | Auth B | Client Secret Google OAuth2 |
| `CWS_REFRESH_TOKEN` | Auth B | Jeton d'actualisation OAuth2 |
| `CWS_PUBLISHER_ID` | Non | ID de l'éditeur (par défaut : `me`) |
| `CWS_ITEM_ID` | Non | ID d'élément d'extension par défaut |

## Exemples d'utilisation

### Vérifier l'état de l'extension
```
Use the cws-mcp status tool
```

La réponse comprend l'état brut de l'API et un résumé établi au mieux. Lorsqu'elles existent, les révisions publiées et soumises sont présentées séparément, avec la version et le pourcentage de déploiement de chaque canal de publication. Les indicateurs de retrait et d'avertissement ainsi que le dernier état d'importation asynchrone sont également affichés lorsqu'ils sont fournis. Un résumé sans problème extrait ne confirme pas l'approbation ; consultez la réponse brute pour les détails. En cas de retrait ou d'avertissement actif, il faut vérifier le Developer Dashboard.

### Importer et publier
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### Publier avec un pourcentage de déploiement initial
```
Use cws-mcp publish with:
- deployPercentage=10
```

À l'inverse, `publishType="STAGED_PUBLISH"` met en attente la version approuvée pour une publication manuelle ; il ne définit pas à lui seul le pourcentage de déploiement. Le type de publication par défaut publie après approbation. `skipReview=true` tente seulement d'omettre l'examen lorsque les conditions sont remplies.

### Publier en omettant l'examen
```
Use cws-mcp publish with skipReview=true
```

### Déploiement progressif
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

Remarque : `deploy-percentage` n'est disponible que pour les extensions comptant au moins 10 000 utilisateurs actifs sur sept jours. Le nouveau pourcentage doit toujours être supérieur à la cible actuelle.

### Annuler une version défectueuse
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

Un rollback est mis en ligne pour tous les utilisateurs en une minute environ, sans examen. Il écarte les soumissions en attente et en préparation et, pendant un déploiement par pourcentage, revient à la dernière version déployée à 100 %. `newVersion` doit être supérieure à la version publiée actuelle. Des rollbacks répétés alternent entre les deux mêmes versions ; assurez-vous donc que l'ancienne version peut gérer les données écrites par la plus récente.

### Avis, notes et métriques
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` accepte au plus une dimension. Les résultats sont paginés ; transmettez le `nextPageToken` renvoyé en tant que `pageToken`, avec des paramètres par ailleurs identiques.

## Dépannage

- **Identifiants manquants / 401 / 403 :** vérifiez l'environnement du processus serveur ainsi que l'accès à l'élément et à l'éditeur. Une clé de compte de service configurée est prioritaire ; des identifiants de compte de service invalides ne basculent pas vers OAuth.
- **Élément manquant / 404 :** créez d'abord l'élément dans le Developer Dashboard, puis transmettez `itemId` ou définissez `CWS_ITEM_ID`. Il n'existe pas d'outil pour lister tous les éléments.
- **ZIP illisible :** `zipPath` doit pointer vers un fichier accessible sur la machine qui exécute le serveur MCP, y compris à l'intérieur de son conteneur le cas échéant. Générez le ZIP avant d'appeler `upload` ou `submit`.
- **Importation encore en cours ou achèvement inconnu :** `upload` et `submit` ne signalent un succès que pour une importation confirmée comme réussie. Sinon, `submit` s'arrête avant la publication ; aucun des deux outils n'effectue d'interrogation automatique. Évitez de relancer une importation ou `submit` tant que le traitement peut se poursuivre. Utilisez `status` pour vérifier `lastAsyncUploadState`, puis utilisez `publish` seul uniquement après avoir confirmé que le ZIP voulu a été traité avec succès. Cet état couvre la dernière importation asynchrone des dernières 24 heures ; si une autre importation a eu lieu ou si l'état est absent ou ambigu, vérifiez d'abord le brouillon dans le Developer Dashboard.
- **Déjà en cours d'examen / version en double :** attendez la fin de l'examen ou utilisez `cancel` avant d'importer ; en cas de version en double, augmentez la version dans le `manifest.json` de l'extension et régénérez son ZIP.
- **État d'importation `NOT_FOUND` :** traité comme une importation échouée ; aucune publication n'est tentée. Revérifiez l'ID de l'élément et réimportez.
- **Importation réussie mais publication échouée :** pour une erreur HTTP, relancez `publish` seul. Si la requête de publication a expiré ou si la connexion a échoué, vérifiez d'abord `status`, car le résultat de la publication est inconnu. Relancer `submit` réimporte le ZIP. `submit` conserve les étapes terminées en cas d'erreur de communication et renvoie un instantané immédiat de l'état ; il n'attend pas la fin de l'examen. Vérifiez à nouveau `status` si l'étape finale d'état a échoué, et consultez la réponse brute lorsqu'un résumé ne contient aucun problème extrait.
- **Erreur liée aux métadonnées héritées :** utilisez le Developer Dashboard comme décrit dans [Métadonnées de la fiche](#métadonnées-de-la-fiche).

## Développement

Pour les commandes de compilation locales et la vérification, consultez [AGENTS.md](AGENTS.md). Pour les limites des composants, la correspondance avec l'API et le comportement en cas d'échec de soumission, consultez [DESIGN.md](DESIGN.md).

## Licence

MIT
