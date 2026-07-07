
# Homebrew (サンドボックス等の非ログインシェルでも有効にする)
# brew が存在する環境でのみ有効化 (macOS=/opt/homebrew, Linux=/home/linuxbrew)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

#AWSume alias to source the AWSume script
alias awsume="source \$(command which awsume)"

#Auto-Complete function for AWSume
fpath=(~/.awsume/zsh-autocomplete/ $fpath)
