
# Homebrew (サンドボックス等の非ログインシェルでも有効にする)
eval "$(/opt/homebrew/bin/brew shellenv)"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

#AWSume alias to source the AWSume script
alias awsume="source \$(command which awsume)"

#Auto-Complete function for AWSume
fpath=(~/.awsume/zsh-autocomplete/ $fpath)
