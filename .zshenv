
# Homebrew (サンドボックス等の非ログインシェルでも有効にする)
# brew が存在する環境でのみ有効化 (macOS=/opt/homebrew, Linux=/home/linuxbrew)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Nix (Homebrew の無い Linux ホスト向け。flake.nix の CLI 一式が ~/.nix-profile/bin に入る)
# インストーラは /etc/zshrc にも追記するが、そちらは対話シェルでしか読まれない。
# brew と同じく非対話シェル (サンドボックス等) でも効かせるため、ここで読み込む。
# 二重読み込みは読み込み先のスクリプト自身が防ぐ。
# 注意: single-user 版の nix.sh は $USER が空だと何もしない (Nix 側の仕様)。
# ログインシェルでは必ず設定されているが、`env -i` で試すときは USER も渡すこと。
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Node.js は Homebrew の node@24 (LTS) を使う。
# keg-only なので /opt/homebrew/bin にはリンクせず、Homebrew の想定どおり PATH に直接通す。
# `brew link --force` すると keg 内の読み取り専用の npm がグローバルのツリーに混ざり、
# npm -g の操作がすべて最後の reifyFinish (npm 自身の npmrc への書き戻し) で EACCES になる。
#
# Volta より前に置く。ログインシェルでは /etc/paths.d/homebrew により path_helper が
# /opt/homebrew/bin を先頭に移すので、従来も Homebrew の node が Volta に勝っていた。
# その挙動を非ログインシェルでも揃える (pnpm は引き続き Volta から解決される)。
if [ -d /opt/homebrew/opt/node@24/bin ]; then
  export PATH="/opt/homebrew/opt/node@24/bin:$PATH"
fi
