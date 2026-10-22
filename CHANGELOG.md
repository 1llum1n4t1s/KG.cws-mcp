# 変更履歴

Git のバージョン記録・コミット差分と既存の変更履歴をもとに、確認できた版ごとの変更点をまとめています。「Git 記録日」は公開日ではありません。番号の欠番だけから未確認のリリースは補っていません。

## 未リリース

## [2.0.4] — 2026-10-22

- 正常なアップロード状態 `SUCCEEDED` を認識し、`submit` が公開処理の前で中断する問題を修正。
- 通信エラー時も完了済みの手順と公開結果の不確実性を保持し、不要な再アップロードを防ぐ案内を追加。
- API エラー、送信前確認、最終状態取得で詳細なレスポンス本文を保持。
- 状態要約に公開版・申請版の状態と、各配信チャネルのバージョン・配信率を追加。
- ZIP 転送前の全量コピーを削減。
- 手動公開待ちと配信率の説明、韓国語の段階配信手順を統一。
- MCP SDK・Zod・Node 型定義と公開 CI の依存関係を更新し、依存更新の検証・自動マージ工程を整備。

## [2.0.3] — Git 記録日: 2026-08-08

- 実行補助ライブラリと CI の依存関係を更新。

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/a9dc84af733d4378b5f08e78808976b1a84454a8) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/9fa2007a63108cf95910a8005a5fb1c07bc6313a...a9dc84af733d4378b5f08e78808976b1a84454a8)。

## [2.0.2] — Git 記録日: 2026-08-07

- typescript を v7 系、@types/node を v26 系へ更新
- zod を v3 系から v4.4.3 へ更新
- 推移的依存の高危険度脆弱性を解消

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/9fa2007a63108cf95910a8005a5fb1c07bc6313a) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/3732927003bc1059cf316907844c72bbcf3071ee...9fa2007a63108cf95910a8005a5fb1c07bc6313a)。

## [2.0.1] — Git 記録日: 2026-06-06

- npm publish を NPM_TOKEN (GitHub Secret) トークン認証に切替

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/3732927003bc1059cf316907844c72bbcf3071ee) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/8c03b4b220704c1d85fba52ed2f9f0e0f79ca205...3732927003bc1059cf316907844c72bbcf3071ee)。

## [2.0.0] — Git 記録日: 2026-06-06

- リリース発火を release/** ブランチ trigger に統一し v2.0.0 へ

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/8c03b4b220704c1d85fba52ed2f9f0e0f79ca205) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/5cc603659746941577f202faa582db313fca7f09...8c03b4b220704c1d85fba52ed2f9f0e0f79ca205)。

## [1.4.4] — Git 記録日: 2026-06-06

- fetch にタイムアウト追加・401/403 でトークンキャッシュ無効化・トークン取得の single-flight 化
- itemId/publisherId/extensionId を URL エンコードし verb/クエリすり替えを防止
- status 要約の fail-silent 解消（拒否理由の取りこぼしを明示・submit に生 status 併記）
- submit の upload 判定をホワイトリスト化・publish 失敗時に「再upload不要」回復ヒント追加
- v1.1 sunset(2026-10-15) 後の get/update-metadata に事前ガード
- resource を apiCall 化＋status/metadata 並列化、itemUrl/buildPublishBody で重複解消

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/5cc603659746941577f202faa582db313fca7f09) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/094fb9ec93de7c83444797fcbd7e2137a6ef338c...5cc603659746941577f202faa582db313fca7f09)。

## [1.4.3] — Git 記録日: 2026-06-05

- Dashboard 日本語表示の label にも対応
- Chrome Web Store API V2 互換改修と自前パッケージ化
- replace __dirname with ESM-compatible import.meta.url for Node.js v25

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/094fb9ec93de7c83444797fcbd7e2137a6ef338c) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/5292130508c6380f3036215f9fb4e9a5dd5b5915...094fb9ec93de7c83444797fcbd7e2137a6ef338c)。

## [1.4.2] — Git 記録日: 2026-03-20

- npm パッケージへライセンスを同梱し、レジストリ掲載用のメタデータと Docker 設定を追加。

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/5292130508c6380f3036215f9fb4e9a5dd5b5915) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/7ff33428ede6c221726f6ae9aea82ca7a177ce35...5292130508c6380f3036215f9fb4e9a5dd5b5915)。

## [1.4.1] — Git 記録日: 2026-03-20

- bump version to 1.4.1 for MCP Registry publish
- add createSandboxServer for Smithery registry
- Add mcpName to package.json and server.json for official MCP Registry
- Add smithery.yaml for Smithery registry listing

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/7ff33428ede6c221726f6ae9aea82ca7a177ce35) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/3346b569e86d1fd5e927057cffa9d9ae1457ab06...7ff33428ede6c221726f6ae9aea82ca7a177ce35)。

## [1.4.0] — Git 記録日: 2026-03-19

- enhance publish tool with staged rollout, skip-review; improve API spec compliance

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/3346b569e86d1fd5e927057cffa9d9ae1457ab06) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/574229552abe268504ddde202cd3bb40ad1c75d3...3346b569e86d1fd5e927057cffa9d9ae1457ab06)。

## [1.3.0] — Git 記録日: 2026-02-19

- add prompts, resources, badge, license for LobeHub score

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/574229552abe268504ddde202cd3bb40ad1c75d3) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/bc5e29c1ce4c8a4bb252bc9a458ebc4c52be7b88...574229552abe268504ddde202cd3bb40ad1c75d3)。

## [1.2.0] — Git 記録日: 2026-02-17

- add dashboard UI metadata automation for CWS

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/bc5e29c1ce4c8a4bb252bc9a458ebc4c52be7b88) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/791a378de36097cd14b81c952818ad181cfee313...bc5e29c1ce4c8a4bb252bc9a458ebc4c52be7b88)。

## [1.1.0] — Git 記録日: 2026-02-17

- expand CWS metadata controls for full listing management
- UPLOAD_BASE URL 및 fetchStatus HTTP method 수정

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/791a378de36097cd14b81c952818ad181cfee313) / [変更差分](https://github.com/1llum1n4t1s/KG.cws-mcp/compare/817d78aea8d07d49f274e34b7e9567ac08ca4272...791a378de36097cd14b81c952818ad181cfee313)。

## [1.0.0] — Git 記録日: 2026-02-16

- Initial commit: CWS-MCP Chrome Web Store MCP server

出典: [版の記録](https://github.com/1llum1n4t1s/KG.cws-mcp/commit/817d78aea8d07d49f274e34b7e9567ac08ca4272)。
