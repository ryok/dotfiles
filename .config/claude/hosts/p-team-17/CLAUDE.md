# User-level CLAUDE.md — host: p-team-17 (shared RTX 6000 Ada GPU server)

このホスト固有のグローバル指示。install.sh が hostname 一致時のみ
`.config/claude/CLAUDE.md` (共有スタブ) を上書きしてリンクする。
`@RTK.md` は共有の `~/.claude/RTK.md` を解決する。

## GPU Usage Notes

- `chrome-headless` を使う際は必ず `--disable-gpu` フラグを付けること。GPU経由でGSPタイムアウト（Xid 120）が発生し、GPU全体がERR!状態になりマシン再起動が必要になる。
- **単一GPU(48GB)に収まらない大きなモデルを `device_map="auto"` / model-parallel でローカル複数GPUに分散ロードしないこと**。GPU間のP2P/peerメモリマッピングが上記と同じGSP障害（`cudaErrorMapBufferObjectFailed` / Xid 119-120）を誘発し、GPUがERR!状態に固定される（30Bを3GPUへ `device_map="auto"` で分散ロードしてGPU 0をERR!化させた実績あり）。
  - 単一48GBに収まらないモデルのローカル実行は避け、**Kaggleの72GB単一GPU**を使う。やむを得ずローカルで動かす場合は事前にユーザーへ確認する。
  - このGPUサーバ(RTX 6000 Ada×3)は**共有**。ERR!状態の復旧は `sudo nvidia-smi --gpu-reset -i <N>`（要root、当該GPUのみ）か再起動だが、再起動は他ユーザーの稼働コンテナを巻き込むため**必ず影響を確認・調整してから**行う（Claude単独で実行しない）。

@RTK.md
