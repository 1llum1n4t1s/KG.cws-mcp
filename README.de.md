# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | **Deutsch** | [Português (Brasil)](README.pt-BR.md)

MCP-Server zur Verwaltung von Erweiterungen im Chrome Web Store. Lade Chrome-Erweiterungen hoch, veröffentliche und verwalte sie direkt aus Claude Code oder jedem MCP-Client.

> Fork von [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp), aktualisiert für die Chrome Web Store **API V2**: Authentifizierung per Dienstkonto, ein funktionierender OAuth-Ablauf (Google hat den alten `oob`-Ablauf entfernt) und das neueste MCP SDK.

## Wann verwenden

Verwende diesen MCP, wenn du Folgendes brauchst:

- **„Eine neue Version meiner Chrome-Erweiterung hochladen"** — erstelle dein ZIP und nutze das Tool `upload`, um es als Entwurf hochzuladen
- **„Meine Erweiterung im Chrome Web Store veröffentlichen"** — nutze `publish`, um sie zur Prüfung einzureichen und live zu schalten
- **„Den Prüfstatus meiner Erweiterung ansehen"** — nutze `status`, um Prüfstatus, Version und Rollout-Prozentsatz zu sehen
- **„Hochladen und veröffentlichen in einem Schritt"** — nutze `submit`, um Upload → Veröffentlichung → Status als einen einzigen Aufruf auszuführen
- **„Eine ausstehende Einreichung abbrechen"** — nutze `cancel`, um eine Einreichung in der Prüfung zurückzuziehen
- **„Gestaffelten Rollout für meine Erweiterung einrichten"** — nutze `publish` mit `deployPercentage` und danach `deploy-percentage`, um schrittweise zu erhöhen
- **„Das neue Release ist defekt, zurückrollen"** — nutze `rollback` (vorher mit `validateOnly=true` validieren)
- **„Meine neuesten Bewertungen / meine Bewertung anzeigen"** — nutze `reviews` und `rating-summary`
- **„Wie viele Installationen und aktive Nutzer hatte ich im letzten Monat?"** — nutze `metrics`

## Tools

| Tool | Beschreibung |
|---|---|
| `upload` | Lädt eine ZIP-Datei in den Chrome Web Store hoch (aktualisiert den Entwurf eines bestehenden Eintrags) |
| `publish` | Veröffentlicht eine Erweiterung, optional mit gestaffeltem Rollout, Veröffentlichungstyp und Überspringen der Prüfung |
| `status` | Ruft den aktuellen Status ab, einschließlich Prüfstatus, Rollout-Prozentsatz und Version |
| `cancel` | Bricht eine ausstehende Einreichung ab |
| `deploy-percentage` | Legt den Prozentsatz des gestaffelten Rollouts fest (0-100, muss über dem aktuellen Ziel liegen) |
| `get`, `update-metadata` | Veraltete Metadaten-Tools; werden vom Server nach seinem v1-Stichtag blockiert (siehe unten) |
| `submit` | Alles in einem: führt Upload → Veröffentlichung → Status in einem einzigen Aufruf aus (mit Existenzprüfung vorab und lesbaren Fehlermeldungen) |
| `rollback` | Veröffentlicht eine zuvor veröffentlichte Version erneut unter einer neuen, höheren Versionsnummer (ohne Prüfung; unterstützt den Probelauf `validateOnly`) |
| `reviews` | Ruft Nutzerbewertungen ab, mit Paginierung, Sortierung (`rating`, `create_time desc`) und Sternefilter |
| `rating-summary` | Ruft die durchschnittliche Bewertung, die Anzahl der Bewertungen und die Anzahl je Stern ab |
| `metrics` | Fragt Installationen, Deinstallationen, tägliche/7-Tage-Nutzer, Impressionen und Seitenaufrufe über einen Zeitraum ab, optional nach einer Dimension aufgeteilt |

`reviews`, `rating-summary` und `metrics` sind schreibgeschützt; sie akzeptieren auch Zugangsdaten, die auf den Scope `https://www.googleapis.com/auth/chromewebstore.readonly` beschränkt sind, der Server fordert für Dienstkonten jedoch den vollständigen Scope `chromewebstore` an.

> Die Chrome Web Store API kann keine Einträge erstellen. Erstelle einen neuen Eintrag manuell im Chrome Web Store Developer Dashboard und verwende dann `upload` / `publish` (oder `submit`) mit dessen Eintrags-ID.

## Metadaten des Eintrags

Der Server blockiert `get` und `update-metadata`, wenn seine Uhr später als **2026-10-15 00:00 UTC** anzeigt, noch bevor eine API-Anfrage gesendet wird. Diese veralteten Tools bleiben in der Tool-Erkennung sichtbar, können nach diesem Stichtag aber nicht mehr verwendet werden. Bearbeite Eintragstexte und andere Metadaten manuell im Chrome Web Store Developer Dashboard; dieser Server bietet weder einen v2-Ersatz für Metadaten noch Browser-Automatisierung.

Nutze `status` für Prüfstatus, Version und Rollout-Informationen. Prompts verweisen für Arbeiten an den Metadaten des Eintrags auf das Developer Dashboard. Die Ressource `cws://extensions/{extensionId}` liefert nach dem Stichtag weiterhin den v2-Status, überspringt die v1-Anfrage und meldet `metadata.unavailable`.

## Einrichtung

Installiere Node.js **20 oder neuer**, um die folgenden `npx`-Beispiele zu verwenden, oder installiere Bun und ersetze `"command": "npx"` und `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` durch `"command": "bunx"` und `"args": ["--bun", "@kagayoi/cws-mcp@latest"]` (entspricht dem Ausführen von `bunx --bun @kagayoi/cws-mcp@latest`), um ohne Node.js zu arbeiten. Keine der beiden Varianten erfordert eine globale Paketinstallation. Mit `@latest` startet jeder Start die neueste npm-Version.

Wenn du den Server bereits mit einer festen Version (zum Beispiel `@kagayoi/cws-mcp@2.0.10`) oder ohne Version (`@kagayoi/cws-mcp`) registriert hast, ändere das Paketargument in dieser Registrierung auf `@kagayoi/cws-mcp@latest`; die Aktualisierung dieser README ändert bestehende Registrierungen nicht, aber nach dieser Änderung verwendet jeder Start automatisch die neueste Version.

Authentifiziere dich **entweder** mit einem Dienstkonto (empfohlen, ideal für CI/CD) **oder** mit einem OAuth2-Refresh-Token.

### Option A — Dienstkonto (empfohlen)

1. Erstelle oder wähle in der [Google Cloud Console](https://console.cloud.google.com/) ein Projekt und aktiviere die **Chrome Web Store API**.
2. Erstelle ein **Dienstkonto** und füge dann einen **JSON-Schlüssel** hinzu (Schlüssel → Schlüssel hinzufügen → Neuen Schlüssel erstellen → JSON).
3. Füge im [Developer Dashboard](https://chrome.google.com/webstore/devconsole) unter **Konto** die E-Mail-Adresse des Dienstkontos hinzu, um ihm API-Zugriff auf dein Publisher-Konto zu gewähren.
4. Setze `CWS_SERVICE_ACCOUNT_KEY` auf den **Pfad der JSON-Schlüsseldatei** (oder deren rohen JSON-Inhalt).

Details findest du unter [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts).

### Option B — OAuth2-Refresh-Token

1. Erstelle oder wähle in der [Google Cloud Console](https://console.cloud.google.com/) ein Projekt und aktiviere die **Chrome Web Store API**.
2. Erstelle **OAuth2-Anmeldedaten** vom Typ **Desktop-App**. Notiere dir die **Client-ID** und das **Client-Secret**.
3. Beziehe ein Refresh-Token über eine **Loopback-Weiterleitung**. (Der alte Ablauf `urn:ietf:wg:oauth:2.0:oob` wurde 2022 von Google entfernt und funktioniert nicht mehr — Desktop-Clients verwenden jetzt `http://localhost`.)

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

   Die Antwort enthält dein `refresh_token`. Für Desktop-App-Clients wird jede Weiterleitung auf `http://localhost[:PORT]` oder `http://127.0.0.1[:PORT]` akzeptiert.

### MCP konfigurieren

Füge die folgende Serverdefinition zur Konfiguration deines MCP-Clients hinzu. Das Beispiel verwendet das Format `mcpServers`; nutze den dokumentierten Konfigurationsort oder den Befehl zum Hinzufügen von Servern deines Clients.

**Über npm mit einem Dienstkonto (empfohlen):**

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

**Über npm mit einem OAuth-Refresh-Token:**

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

## Umgebungsvariablen

Gib **entweder** einen Dienstkonto-Schlüssel (Auth A) **oder** das OAuth2-Refresh-Token-Trio (Auth B) an.

| Variable | Erforderlich | Beschreibung |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | Auth A | Pfad zu einer JSON-Schlüsseldatei des Dienstkontos oder der rohe JSON-String. Hat Vorrang vor OAuth, wenn gesetzt. |
| `CWS_CLIENT_ID` | Auth B | Google OAuth2 Client-ID |
| `CWS_CLIENT_SECRET` | Auth B | Google OAuth2 Client-Secret |
| `CWS_REFRESH_TOKEN` | Auth B | OAuth2-Refresh-Token |
| `CWS_PUBLISHER_ID` | Nein | Publisher-ID (Standard: `me`) |
| `CWS_ITEM_ID` | Nein | Standard-Eintrags-ID der Erweiterung |

## Anwendungsbeispiele

### Status der Erweiterung prüfen
```
Use the cws-mcp status tool
```

Die Antwort enthält den rohen API-Status und eine Zusammenfassung nach bestem Bemühen. Falls vorhanden, werden veröffentlichte und eingereichte Revisionen getrennt angezeigt, jeweils mit Version und Rollout-Prozentsatz des Release-Kanals. Takedown- und Warnungs-Flags sowie der letzte asynchrone Upload-Status werden ebenfalls angezeigt, sofern sie geliefert werden. Eine Zusammenfassung ohne extrahierte Probleme bestätigt keine Freigabe; prüfe die rohe Antwort auf Details. Bei aktiven Takedowns oder Warnungen ist eine Kontrolle im Developer Dashboard erforderlich.

### Hochladen und veröffentlichen
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### Mit anfänglichem Rollout-Prozentsatz veröffentlichen
```
Use cws-mcp publish with:
- deployPercentage=10
```

`publishType="STAGED_PUBLISH"` hält stattdessen die genehmigte Version für die manuelle Veröffentlichung bereit; es legt nicht selbst den Rollout-Prozentsatz fest. Der Standard-Veröffentlichungstyp veröffentlicht nach der Genehmigung. `skipReview=true` versucht nur dann, die Prüfung zu überspringen, wenn die Voraussetzungen erfüllt sind.

### Mit Überspringen der Prüfung veröffentlichen
```
Use cws-mcp publish with skipReview=true
```

### Gestaffelter Rollout
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

Hinweis: `deploy-percentage` ist nur für Erweiterungen mit mindestens 10.000 aktiven Nutzern in 7 Tagen verfügbar. Der neue Prozentsatz muss immer höher sein als das aktuelle Ziel.

### Ein fehlerhaftes Release zurückrollen
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

Ein Rollback geht innerhalb von etwa einer Minute ohne Prüfung für alle Nutzer live. Er verwirft ausstehende und gestaffelte Einreichungen und kehrt bei einem prozentualen Rollout zur letzten Version zurück, die zu 100 % ausgeliefert wurde. `newVersion` muss höher sein als die aktuell veröffentlichte Version. Wiederholte Rollbacks wechseln zwischen denselben zwei Versionen; stelle daher sicher, dass die ältere Version mit den von der neueren geschriebenen Daten umgehen kann.

### Bewertungen, Ratings und Metriken
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` akzeptiert höchstens eine Dimension. Die Ergebnisse sind paginiert; übergib das zurückgegebene `nextPageToken` als `pageToken` bei sonst identischen Parametern.

## Fehlerbehebung

- **Fehlende Zugangsdaten / 401 / 403:** prüfe die Umgebung des Serverprozesses sowie den Zugriff auf Eintrag/Publisher. Ein konfigurierter Dienstkonto-Schlüssel hat Vorrang; ungültige Dienstkonto-Zugangsdaten fallen nicht auf OAuth zurück.
- **Fehlender Eintrag / 404:** erstelle den Eintrag zuerst im Developer Dashboard und übergib dann `itemId` oder setze `CWS_ITEM_ID`. Es gibt kein Tool zum Auflisten aller Einträge.
- **ZIP nicht lesbar:** `zipPath` muss auf eine Datei zeigen, die auf dem Rechner zugänglich ist, auf dem der MCP-Server läuft, gegebenenfalls auch innerhalb seines Containers. Erstelle das ZIP, bevor du `upload` oder `submit` aufrufst.
- **Upload wird noch verarbeitet oder Abschluss unbekannt:** `upload` und `submit` melden nur bei einem bestätigten erfolgreichen Upload Erfolg. Andernfalls stoppt `submit` vor der Veröffentlichung; keines der Tools fragt automatisch ab. Vermeide einen weiteren Upload oder die Wiederholung von `submit`, solange die Verarbeitung noch laufen kann. Prüfe mit `status` den Wert `lastAsyncUploadState` und nutze `publish` allein erst, nachdem du bestätigt hast, dass das beabsichtigte ZIP erfolgreich war. Dieser Status betrifft den letzten asynchronen Upload innerhalb von 24 Stunden. Wenn also ein weiterer Upload stattfand oder der Status fehlt oder mehrdeutig ist, überprüfe zuerst den Entwurf im Developer Dashboard.
- **Bereits in Prüfung / doppelte Version:** warte auf die Prüfung oder nutze `cancel`, bevor du hochlädst; bei einer doppelten Version erhöhe die Version in der `manifest.json` der Erweiterung und erstelle ihr ZIP neu.
- **Upload-Status `NOT_FOUND`:** wird als fehlgeschlagener Upload behandelt; eine Veröffentlichung wird nicht versucht. Prüfe die Eintrags-ID erneut und lade erneut hoch.
- **Upload erfolgreich, aber Veröffentlichung fehlgeschlagen:** bei einem HTTP-Fehler wiederhole nur `publish`. Wenn bei der Veröffentlichungsanfrage ein Timeout oder ein Verbindungsfehler auftrat, prüfe zuerst `status`, da das Ergebnis der Veröffentlichung unbekannt ist. Ein erneutes Ausführen von `submit` lädt das ZIP erneut hoch. `submit` behält abgeschlossene Schritte bei Kommunikationsfehlern bei und liefert einen sofortigen Status-Snapshot; es wartet nicht auf den Abschluss der Prüfung. Prüfe `status` erneut, wenn der letzte Statusschritt fehlgeschlagen ist, und untersuche die rohe Antwort, wenn eine Zusammenfassung keine extrahierten Probleme enthält.
- **Fehler bei veralteten Metadaten:** nutze das Developer Dashboard, wie unter [Metadaten des Eintrags](#metadaten-des-eintrags) beschrieben.

## Entwicklung

Lokale Build-Befehle und Verifikation findest du in [AGENTS.md](AGENTS.md). Komponentengrenzen, API-Zuordnung und das Verhalten bei Einreichungsfehlern findest du in [DESIGN.md](DESIGN.md).

## Lizenz

MIT
