
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
