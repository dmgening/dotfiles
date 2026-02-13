# AI Commands Setup

This dotfiles repo includes support for AI-powered command generation using OpenAI.

## Prerequisites

You need an OpenAI API key. With your **OpenAI Pro subscription**, you have API access.

## Setup Instructions

### 1. Get Your OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy the key (starts with `sk-...`)

### 2. Add API Key to Your Shell

Create a local secrets file that won't be committed to git:

```bash
# Create secrets file
touch ~/.config/zsh/secrets.sh

# Add your API key
echo 'export ZSH_AI_COMMANDS_OPENAI_API_KEY="sk-your-key-here"' >> ~/.config/zsh/secrets.sh

# Secure the file (only you can read it)
chmod 600 ~/.config/zsh/secrets.sh
```

**Alternative**: Add to `~/.zshenv` (loaded before .zshrc):
```bash
echo 'export ZSH_AI_COMMANDS_OPENAI_API_KEY="sk-your-key-here"' >> ~/.zshenv
chmod 600 ~/.zshenv
```

### 3. Reload Your Shell

```bash
exec zsh
```

Or open a new terminal.

### 4. Verify Setup

```bash
# Check if plugin loaded
echo $ZSH_AI_COMMANDS_HOTKEY  # Should output: ^o

# Check if API key is set
[[ -n "$ZSH_AI_COMMANDS_OPENAI_API_KEY" ]] && echo "API key is set" || echo "API key missing"
```

## Usage

### Generate Command from Natural Language

Press **Ctrl+O** (the configured hotkey), then type what you want:

```
find all files larger than 100MB modified this week
```

The AI will generate:
```bash
find . -type f -size +100M -mtime -7
```

Press **Enter** to execute, or **Esc** to cancel.

### Examples

```
Ctrl+O: "compress all .log files to a tarball"
→ tar -czf logs.tar.gz *.log

Ctrl+O: "show me my top 10 largest directories"
→ du -sh */ | sort -rh | head -10

Ctrl+O: "kill all processes containing 'node'"
→ pkill -f node

Ctrl+O: "find python files with TODO comments"
→ grep -r "TODO" --include="*.py" .
```

## Cost

With OpenAI Pro, API calls are cheap:
- ~$0.002 per command generation
- Uses GPT-4 by default
- No additional subscription needed (you have API access)

## Configuration

The plugin is configured in:
- `config.d/910-ai-commands.sh` - Plugin loading and hotkey
- `~/.config/zsh/secrets.sh` - Your API key (not in git)

### Change Hotkey

Edit `config.d/910-ai-commands.sh`:
```bash
ZSH_AI_COMMANDS_HOTKEY="^x"  # Ctrl+X instead of Ctrl+O
```

### Advanced Configuration

See plugin docs: https://github.com/muePatrick/zsh-ai-commands

## Troubleshooting

**Plugin doesn't load:**
```bash
# Check if API key is set
echo $OPENAI_API_KEY

# Manually load plugin
zinit light muePatrick/zsh-ai-commands
```

**Ctrl+O doesn't work:**
```bash
# Check hotkey binding
bindkey | grep ai-commands

# Reload config
source ~/.zshrc
```

**API errors:**
- Verify your API key at https://platform.openai.com/api-keys
- Check API usage limits
- Ensure key has correct permissions

## Security Notes

- ✓ API key stored in `~/.config/zsh/secrets.sh` (gitignored)
- ✓ File permissions set to 600 (only you can read)
- ✗ Never commit API keys to git
- ✗ Never share your secrets.sh file

## Uninstall

Remove or comment out in `config.d/910-ai-commands.sh`:
```bash
# zinit light muePatrick/zsh-ai-commands
```
