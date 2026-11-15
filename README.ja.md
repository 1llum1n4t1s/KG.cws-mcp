# @kagayoi/cws-mcp

[![npm version](https://img.shields.io/npm/v/@kagayoi/cws-mcp)](https://www.npmjs.com/package/@kagayoi/cws-mcp)

[English](README.md) | **日本語** | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português (Brasil)](README.pt-BR.md)

Chrome ウェブストアの拡張機能を管理するための MCP サーバーです。Claude Code や任意の MCP クライアントから、Chrome 拡張機能のアップロード、公開、管理を直接行えます。

> [mikusnuz/cws-mcp](https://github.com/mikusnuz/cws-mcp) のフォークで、Chrome ウェブストア **API V2** に対応しています。サービスアカウント認証、動作する OAuth フロー（Google が従来の `oob` フローを廃止したため）、最新の MCP SDK を備えています。

## 利用シーン

この MCP は次のような場合に使います。

- **「Chrome 拡張機能の新しいバージョンをアップロードしたい」** — ZIP をビルドし、`upload` ツールで下書きとしてアップロードします
- **「拡張機能を Chrome ウェブストアに公開したい」** — `publish` で審査に提出し、公開します
- **「拡張機能の審査状況を確認したい」** — `status` で審査状態、バージョン、デプロイ率を確認します
- **「アップロードと公開を一度に行いたい」** — `submit` で upload → publish → status を 1 回の呼び出しで実行します
- **「審査中の提出を取り消したい」** — `cancel` で審査中の提出を取り下げます
- **「拡張機能を段階的にロールアウトしたい」** — `deployPercentage` を指定して `publish` を実行し、その後 `deploy-percentage` で割合を引き上げます
- **「新しいリリースに不具合があるのでロールバックしたい」** — `rollback` を使います（先に `validateOnly=true` で検証してください）
- **「最新のレビューや評価を見たい」** — `reviews` と `rating-summary` を使います
- **「先月のインストール数とアクティブユーザー数を知りたい」** — `metrics` を使います

## ツール

| ツール | 説明 |
|---|---|
| `upload` | ZIP ファイルを Chrome ウェブストアにアップロードします（既存アイテムの下書きを更新） |
| `publish` | 拡張機能を公開します。段階的ロールアウト、公開タイプ、審査スキップを任意で指定できます |
| `status` | 審査状態、デプロイ率、バージョンを含む現在のステータスを取得します |
| `cancel` | 保留中の提出をキャンセルします |
| `deploy-percentage` | 段階的ロールアウトの割合を設定します（0-100。現在の目標値を上回る必要があります） |
| `get`, `update-metadata` | レガシーのメタデータツールです。v1 の打ち切り日以降はサーバーによってブロックされます（下記参照） |
| `submit` | ワンショット実行: upload → publish → status を 1 回の呼び出しで実行します（存在確認の事前チェックと読みやすいエラー付き） |
| `rollback` | 以前に公開したバージョンを、より大きい新しいバージョン番号で再公開します（審査なし。`validateOnly` のドライランに対応） |
| `reviews` | ユーザーレビューを取得します。ページネーション、並べ替え（`rating`、`create_time desc`）、評価フィルターに対応します |
| `rating-summary` | 平均評価、評価数、星ごとの件数を取得します |
| `metrics` | 指定した期間のインストール数、アンインストール数、日次・7 日間ユーザー数、インプレッション、ページビューを取得します。任意で 1 つのディメンションで分割できます |

`reviews`、`rating-summary`、`metrics` は読み取り専用です。`https://www.googleapis.com/auth/chromewebstore.readonly` スコープのみの認証情報でも利用できますが、サーバーはサービスアカウントに対して完全な `chromewebstore` スコープを要求します。

> Chrome ウェブストア API ではアイテムを新規作成できません。まず Chrome ウェブストアの Developer Dashboard で手動で新しいアイテムを作成し、そのアイテム ID に対して `upload` / `publish`（または `submit`）を使ってください。

## 掲載情報メタデータ

サーバーは、時計が **2026-10-15 00:00 UTC** を過ぎている場合、API リクエストを行う前に `get` と `update-metadata` をブロックします。これらのレガシーツールはツール一覧には表示され続けますが、この期日以降は使用できません。掲載文などのメタデータは Chrome ウェブストアの Developer Dashboard で手動で編集してください。このサーバーには v2 のメタデータ代替機能もブラウザー自動操作もありません。

審査状態、バージョン、ロールアウト情報の確認には `status` を使ってください。プロンプトは、掲載情報メタデータの作業を Developer Dashboard へ誘導します。`cws://extensions/{extensionId}` リソースは、期日以降も v2 のステータスを返し、v1 リクエストを行わず、`metadata.unavailable` を報告します。

## セットアップ

以下の `npx` の例を使うには **20 以上**の Node.js をインストールしてください。または Bun をインストールし、`"command": "npx"` と `"args": ["--yes", "@kagayoi/cws-mcp@latest"]` を `"command": "bunx"` と `"args": ["--bun", "@kagayoi/cws-mcp@latest"]` に置き換えると（`bunx --bun @kagayoi/cws-mcp@latest` の実行と同じ）、Node.js なしで実行できます。どちらもグローバルへのパッケージのインストールは不要です。`@latest` を指定すると、起動のたびに最新の npm リリースが実行されます。

すでにバージョンを固定して（例: `@kagayoi/cws-mcp@2.0.10`）、またはバージョンなし（`@kagayoi/cws-mcp`）でサーバーを登録している場合は、その登録内のパッケージ引数を `@kagayoi/cws-mcp@latest` に変更してください。この README を更新しても既存の登録は変わりませんが、変更後は起動のたびに自動で最新リリースが使われます。

認証には、サービスアカウント（推奨、CI/CD に最適）**または** OAuth2 リフレッシュトークンの**どちらか**を使います。

### オプション A — サービスアカウント（推奨）

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成または選択し、**Chrome Web Store API** を有効にします。
2. **サービスアカウント**を作成し、**JSON キー**を追加します（キー → 鍵を追加 → 新しい鍵を作成 → JSON）。
3. [Developer Dashboard](https://chrome.google.com/webstore/devconsole) → **アカウント**で、サービスアカウントのメールアドレスを追加し、パブリッシャーアカウントへの API アクセスを許可します。
4. `CWS_SERVICE_ACCOUNT_KEY` に **JSON キーファイルのパス**（または生の JSON 内容）を設定します。

詳細は [Use a service account with the Chrome Web Store API](https://developer.chrome.com/docs/webstore/service-accounts) を参照してください。

### オプション B — OAuth2 リフレッシュトークン

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成または選択し、**Chrome Web Store API** を有効にします。
2. **デスクトップアプリ**タイプの **OAuth2 認証情報**を作成します。**クライアント ID** と**クライアント シークレット**を控えておきます。
3. **ループバックリダイレクト**を使ってリフレッシュトークンを取得します。（従来の `urn:ietf:wg:oauth:2.0:oob` フローは 2022 年に Google により廃止され、使用できません。デスクトップクライアントは現在 `http://localhost` を使用します。）

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

   レスポンスに `refresh_token` が含まれます。デスクトップアプリのクライアントでは、`http://localhost[:PORT]` または `http://127.0.0.1[:PORT]` のリダイレクトであればどれも受け付けられます。

### MCP の設定

次のサーバー定義を、お使いの MCP クライアントの設定に追加します。例では `mcpServers` 形式を使っています。クライアントが案内する設定ファイルの場所やサーバー追加コマンドを使ってください。

**npm 経由でサービスアカウントを使う場合（推奨）:**

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

**npm 経由で OAuth リフレッシュトークンを使う場合:**

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

## 環境変数

サービスアカウントキー（認証 A）**または** OAuth2 リフレッシュトークンの 3 点セット（認証 B）の**どちらか**を指定してください。

| 変数 | 必須 | 説明 |
|---|---|---|
| `CWS_SERVICE_ACCOUNT_KEY` | 認証 A | サービスアカウントの JSON キーファイルのパス、または生の JSON 文字列。設定されている場合は OAuth より優先されます。 |
| `CWS_CLIENT_ID` | 認証 B | Google OAuth2 クライアント ID |
| `CWS_CLIENT_SECRET` | 認証 B | Google OAuth2 クライアント シークレット |
| `CWS_REFRESH_TOKEN` | 認証 B | OAuth2 リフレッシュトークン |
| `CWS_PUBLISHER_ID` | 不要 | パブリッシャー ID（既定値: `me`） |
| `CWS_ITEM_ID` | 不要 | 既定の拡張機能アイテム ID |

## 使用例

### 拡張機能のステータスを確認する
```
Use the cws-mcp status tool
```

レスポンスには、API の生のステータスと、ベストエフォートの要約が含まれます。存在する場合は、公開済みリビジョンと提出済みリビジョンが別々に表示され、各リリースチャンネルのバージョンとロールアウト率も示されます。提供されている場合は、削除措置や警告のフラグ、直近の非同期アップロードの状態も表示されます。抽出された問題がない要約は、承認を確認するものではありません。詳細は生のレスポンスで確認してください。有効な削除措置や警告がある場合は、Developer Dashboard で確認が必要です。

### アップロードして公開する
```
1. Use cws-mcp upload with zipPath="/path/to/extension.zip"
2. Use cws-mcp publish
```

### 初期ロールアウト率を指定して公開する
```
Use cws-mcp publish with:
- deployPercentage=10
```

代わりに `publishType="STAGED_PUBLISH"` を指定すると、承認されたバージョンは手動公開用にステージングされます。これ自体はロールアウト率を設定しません。既定の公開タイプでは、承認後に公開されます。`skipReview=true` は、対象となる場合にのみ審査のスキップを試みます。

### 審査スキップで公開する
```
Use cws-mcp publish with skipReview=true
```

### 段階的ロールアウト
```
1. Use cws-mcp publish with deployPercentage=10
2. After approval and publication, check the current target with cws-mcp status
3. Use cws-mcp deploy-percentage with percentage=50
4. Use cws-mcp deploy-percentage with percentage=100
```

注: `deploy-percentage` は、7 日間のアクティブユーザーが 10,000 人以上の拡張機能でのみ利用できます。新しい割合は常に現在の目標値より高くする必要があります。

### 不具合のあるリリースをロールバックする
```
1. Use cws-mcp rollback with newVersion="1.2.1", rollbackReason="crash on startup", validateOnly=true
2. If validation succeeds, run the same call without validateOnly
3. Use cws-mcp status to confirm the published revision
```

ロールバックは審査なしで、約 1 分以内にすべてのユーザーに反映されます。保留中およびステージング中の提出は破棄され、割合によるロールアウトの途中では、100% でデプロイされた最後のバージョンに戻ります。`newVersion` は現在公開中のバージョンより高くする必要があります。ロールバックを繰り返すと同じ 2 つのバージョンの間を行き来することになるため、古いバージョンが新しいバージョンで書き込まれたデータを扱えることを確認してください。

### レビュー、評価、メトリクス
```
Use cws-mcp reviews with orderBy="create_time desc", pageSize=20
Use cws-mcp reviews with filter="rating = 1"
Use cws-mcp rating-summary
Use cws-mcp metrics with metrics=["installs","users-7d"], firstDate="2026-10-01", lastDate="2026-10-31", dimension="country"
```

`metrics` が受け付けるディメンションは最大 1 つです。結果はページネーションされます。返された `nextPageToken` を `pageToken` として渡し、他のパラメーターは同一にしてください。

## トラブルシューティング

- **認証情報がない / 401 / 403:** サーバープロセスの環境と、アイテムおよびパブリッシャーへのアクセス権を確認してください。設定済みのサービスアカウントキーが優先され、無効なサービスアカウント認証情報の場合も OAuth にはフォールバックしません。
- **アイテムがない / 404:** 先に Developer Dashboard でアイテムを作成し、`itemId` を渡すか `CWS_ITEM_ID` を設定してください。すべてのアイテムを一覧表示するツールはありません。
- **ZIP を読み取れない:** `zipPath` は、MCP サーバーを実行しているマシン（コンテナー内で実行している場合はそのコンテナー内を含む）からアクセスできるファイルを指す必要があります。`upload` や `submit` を呼び出す前に ZIP をビルドしてください。
- **アップロードが処理中、または完了状態が不明:** `upload` と `submit` は、アップロードの成功が確認できた場合にのみ成功を報告します。それ以外の場合、`submit` は公開の前に停止します。どちらのツールも自動ではポーリングしません。処理が続いている可能性がある間は、再度アップロードしたり `submit` を繰り返したりしないでください。`status` で `lastAsyncUploadState` を確認し、意図した ZIP が成功したことを確認してから、`publish` のみを使ってください。このステータスは 24 時間以内の最新の非同期アップロードを対象とします。別のアップロードが行われた場合や、状態がない、または曖昧な場合は、まず Developer Dashboard で下書きを確認してください。
- **すでに審査中 / バージョンの重複:** 審査が終わるのを待つか、`cancel` を使ってからアップロードしてください。バージョンが重複している場合は、拡張機能の `manifest.json` のバージョンを上げて ZIP をビルドし直してください。
- **アップロード状態が `NOT_FOUND`:** アップロード失敗として扱われ、公開は試行されません。アイテム ID を再確認し、もう一度アップロードしてください。
- **アップロードは成功したが公開に失敗した:** HTTP エラーの場合は、`publish` のみを再試行してください。公開リクエストがタイムアウトした、または接続に失敗した場合は、公開結果が不明なため、まず `status` を確認してください。`submit` を再実行すると ZIP が再度アップロードされます。`submit` は通信エラー時に完了済みのステップを保持し、直後のステータスのスナップショットを返します。審査の完了を待つことはありません。最後のステータスのステップが失敗した場合は、再度 `status` を確認し、要約に抽出された問題がない場合は生のレスポンスを確認してください。
- **レガシーメタデータのエラー:** [掲載情報メタデータ](#掲載情報メタデータ) の説明に従い、Developer Dashboard を使用してください。

## 開発

ローカルのビルドコマンドと検証については [AGENTS.md](AGENTS.md) を参照してください。コンポーネントの境界、API のマッピング、提出失敗時の動作については [DESIGN.md](DESIGN.md) を参照してください。

## ライセンス

MIT
