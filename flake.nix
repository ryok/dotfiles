{
  # Homebrew の無い Linux ホスト (共有 GPU サーバ p-team-17 など) 向けの CLI 一式。
  # .bin/bootstrap.sh が `nix profile install .#default` で導入する。
  #
  # 範囲はツールの供給だけ。dotfiles のリンクは引き続き install.sh が担う:
  # Claude Code / Codex は設定ファイルを自分で書き戻すため、home-manager の
  # 読み取り専用 (/nix/store) リンクとは相性が悪い。macOS は Homebrew のまま。
  description = "CLI toolchain for hosts without Homebrew";

  # nixos-unstable は Hydra のビルドが通ってから進むチャネルなので、
  # cache.nixos.org にビルド済みのものがあり、ホスト上でのソースビルドが起きない。
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        # `nix profile` の要素名は、属性名が default だと flake のディレクトリ名
        # (置き場所しだいで変わる) になる。名前付きの属性で入れて要素名を
        # dotfiles-cli に固定し、bootstrap.sh が upgrade 対象を確実に特定できるようにする。
        default = dotfiles-cli;
        dotfiles-cli = pkgs.buildEnv {
          name = "dotfiles-cli";
          # 基準: この dotfiles 自身が参照しているもの。
          paths = with pkgs; [
            # Claude Code 周り
            rtk # PreToolUse フック (settings.json)
            agent-browser # agent-browser スキル (skills/ も同梱)
            herdr # .config/herdr/

            # git 周り (.gitconfig / .bin/git-*.sh)
            delta # core.pager (.bin/git-delta.sh)
            git-lfs # filter.lfs
            gh # credential helper / レビュー系スキル
            jq # clean filter (.bin/git-jsonsort.sh)

            # lint (.config/claude/rules/)
            shellcheck
            actionlint

            # シェル (.zshrc)
            starship
            zoxide
            fzf
            eza
            bat
            direnv
            uv
            ripgrep

            # tmux は入れない: 共有ホストでは既存の tmux サーバが常駐しており、
            # クライアントとバージョンがずれると "protocol version mismatch" で
            # 既存セッションに入れなくなる。システムの tmux を使う。
          ];
        };
      });
    };
}
