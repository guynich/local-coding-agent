**Local Coding Agent**

A minimal guide to running a local AI coding agent safely in a macOS standard
user account using Ollama and Qwen Code.  No internet connection needed.

Table of contents:
- [Background](#background)
- [Requirements](#requirements)
- [Accounts](#accounts)
- [1. Ollama (Admin Account)](#1-ollama-admin-account)
- [2. SSH from Admin to Sandbox](#2-ssh-from-admin-to-sandbox)
- [3. Qwen Code (Sandbox Account)](#3-qwen-code-sandbox-account)
- [Usage](#usage)
- [Maintenance](#maintenance)
  - [Ollama memory use](#ollama-memory-use)
  - [Qwen Code Version](#qwen-code-version)
- [References](#references)

## Background

This guide uses steps from this
[excellent post by Sebastian Raschka](https://magazine.sebastianraschka.com/p/using-local-coding-agents) - read it first.

This guide adds:
1. Sandboxing for safety (standard account, plus
[Qwen Code's sandbox](https://qwenlm.github.io/qwen-code-docs/en/users/features/sandbox/)
)
2. Model parameters for coding

## Requirements

- macOS with Apple Silicon and sufficient memory to run a 22GB model (tested on MacBook Pro 48GB)
- Two macOS accounts:
  - **Admin** (primary, e.g. `myname` or `main`)
  - **Sandbox** (standard user, e.g. `sandboxuser` or `agent`)
- Ollama installed on the **admin** account

## Accounts

The sandbox account prevents AI agents from accessing your personal or
company data stored in the admin home directory.

Key points:

- Admin account can protect custom folders with `chmod 700 ~/<foldername>`
- SSH access from admin account lets you edit in the sandbox, e.g.: use terminal or use VS Code with `Remote - SSH` extension

## 1. Ollama (Admin Account)

Install Ollama and pull the Qwen 3.6 coding model (the `qwen3.6:35b-mlx`
model with two parameters changed for coding).

```bash
brew install --cask ollama
ollama pull qwen3.6:35b-a3b-coding-nvfp4
```

> Tag may change — check ollama.com/library/qwen3.6 if this tag fails.

Launch the Ollama app and disable Auto-download updates; use
`brew upgrade` instead.

## 2. SSH from Admin to Sandbox

Set Remote Login **on** in macOS Sharing settings for the **sandbox user**.

Configure `~/.ssh/config` on the admin account:

```ssh
Host sandbox
  HostName localhost
  User sandboxuser
```

Ensure the admin account can SSH into the sandbox:

```bash
ssh sandbox  # From admin to sandbox
```

You do not need to login to the user account using macOS GUI for this SSH
connection to work.

Beyond the scope of this guide are generating a key and copying to authorized users file on the sandbox account.

## 3. Qwen Code (Sandbox Account)

SSH from admin into the sandbox account, then install:
```bash
curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen-standalone.sh | bash
qwen --version
```

Set up Qwen Code to use the local Ollama model:

1. Edit `~/.qwen/settings.json`
2. **Custom Provider**:
   - Protocol: OpenAI-compatible
   - Base URL: `http://127.0.0.1:11434/v1`
   - API Key: `ollama`
   - Model ID: `qwen3.6:35b-a3b-coding-nvfp4`

These are minimal settings for a local-only setup:

```json
{
  "privacy": { "usageStatisticsEnabled": false },
  "general": { "enableAutoUpdate": false },
  "telemetry": { "enabled": false, "logPrompts": false },
  "mcpServers": {},
  "artifact": { "publisher": "local", "autoOpen": false },
  "tools": { "approvalMode": "default", "sandbox": true }
}
```

Note this uses Qwen Code's sandbox for added safety.

## Usage

In a terminal:
```bash
ssh sandbox
```
Then run Qwen Code in that shell, in your project folder:
```bash
cd ~/src/my-project
qwen
```

## Maintenance

### Ollama memory use

This setup can consume significant memory. Avoid running both `Ollama.app` and
`ollama serve` simultaneously to prevent loading the model twice.

### Qwen Code Version

Check the version with `qwen --version`. Re-run the install script to upgrade.

## References

Excellent post.
- https://magazine.sebastianraschka.com/p/using-local-coding-agents

Qwen Code.
- https://github.com/QwenLM/qwen-code
- https://qwenlm.github.io/qwen-code-docs/en/users/configuration/settings/#permissions
- https://qwenlm.github.io/qwen-code-docs/en/users/features/sandbox/#quickstart

Ollama Qwen3.6 models.
- https://ollama.com/library/qwen3.6/tags
