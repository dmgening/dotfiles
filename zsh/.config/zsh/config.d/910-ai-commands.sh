#!/usr/bin/env zsh

if [[ -n "$ZSH_AI_COMMANDS_OPENAI_API_KEY" ]]; then
  export ZSH_AI_COMMANDS_HOTKEY="^o"
  
  zinit ice lucid
  zinit light muePatrick/zsh-ai-commands
fi
