# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ $(tty) == *"pts"* ]]; then
    fastfetch --config examples/13 --logo arch
fi
for f in ~/.config/zshrc/*; do
    if [ ! -d $f ]; then
        c=`echo $f | sed -e "s=.config/zshrc=.config/zshrc/custom="`
        [[ -f $c ]] && source $c || source $f
    fi
done

# -----------------------------------------------------
# Load single customization file (if exists)
# -----------------------------------------------------

if [ -f ~/.zshrc_custom ]; then
    source ~/.zshrc_custom
fi

eval "$(mise activate zsh)"
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi

# proto
export PROTO_HOME="$HOME/.proto";
export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";

export TFC_COMMAND="yazi --chooser-file=/dev/stdout"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
