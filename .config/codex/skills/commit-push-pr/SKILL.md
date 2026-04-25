---
name: commit-push-pr
description: "Use when the user wants Codex to take completed local changes through the standard git handoff: create a branch if needed, make a commit, push it, and open a pull request with `gh`."
---

# Commit Push PR

ローカル変更を GitHub に引き渡すところまで一気通貫で進める。

## 実行フロー

1. `git status` と `git diff HEAD` で変更内容を確認する
2. `main` や `master` にいる場合は作業ブランチを切る
3. 意図が明確な単位で `git add` と `git commit` を行う
4. `git push -u origin <branch>` で push する
5. `gh pr create` で PR を作る

## 注意事項

- 変更内容を要約した上で、適切なコミットメッセージと PR タイトルを付ける
- push や PR 作成のようなネットワーク操作は Codex の承認フローに従う
- 既存の未整理変更がある場合は、それを巻き込まないように注意する
