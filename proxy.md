**Proxy Setup — Tinyproxy + Seatbelt for Qwen Code**

This guide walks through setting up a lightweight local forward proxy outside
the sandbox to restrict Qwen Code's internet and file system access.

- [Admin account](#admin-account)
  - [Install Tinyproxy](#install-tinyproxy)
- [Sandbox standard account](#sandbox-standard-account)
  - [1. Add Seatbelt profile in your project](#1-add-seatbelt-profile-in-your-project)
  - [2. Add environment variables](#2-add-environment-variables)
  - [3. Edit SSH config for github.com](#3-edit-ssh-config-for-githubcom)
  - [4. Testing](#4-testing)
- [Troubleshooting](#troubleshooting)
  - [Missing profile .sb](#missing-profile-sb)

## Admin account

### Install Tinyproxy

Install and start Tinyproxy on the **admin** account:

```sh
brew install tinyproxy
brew services start tinyproxy
```

Configure it at `/opt/homebrew/etc/tinyproxy/tinyproxy.conf`. Append:

```plaintext
# Qwen Code Seatbelt proxied profile
Port 8877
Listen 127.0.0.1

# Domain filtering
Filter "/opt/homebrew/etc/tinyproxy/allowed_domains"
FilterDefaultDeny Yes
FilterType fnmatch
```

Edit the allow-list at
`/opt/homebrew/etc/tinyproxy/allowed_domains` for your needs.

e.g.:
```
*.github.com
github.com
*.githubusercontent.com
githubusercontent.com
*.pypi.org
pypi.org
*.pythonhosted.org
pythonhosted.org
*.npmjs.org
npmjs.org
*.crates.io
crates.io
*.stackoverflow.com
stackoverflow.com
*.ollama.com
ollama.com
qwen-code-assets.oss-cn-hangzhou.aliyuncs.com
*.googleapis.com
googleapis.com
*.googleusercontent.com
googleusercontent.com
```

Restart the proxy:

```sh
brew services restart tinyproxy
```

## Sandbox standard account

### 1. Add Seatbelt profile in your project

Copy the Qwen Code
[permissive-proxied profile](https://github.com/QwenLM/qwen-code/blob/main/packages/cli/src/utils/sandbox-macos-permissive-proxied.sb)
into your project's `.qwen` folder.

After the `(allow default)` line, add these two lines:

```scheme
;; Blocks agent from reading mounted external drives and network shares
(deny file-read* (subpath "/Volumes"))
```
```scheme
;; Enables agent to access Ollama
(allow network-outbound (remote tcp "localhost:11434"))
```

The file must be renamed to
`sandbox-macos-permissive-proxied-ollama.sb`.

### 2. Add environment variables

Add these to the sandbox account's shell rc file (`~/.bashrc` or
`~/.zshrc`):

```sh
# Seatbelt proxied profile
export QWEN_SANDBOX=sandbox-exec
export SEATBELT_PROFILE=permissive-proxied-ollama

# Route CLI tools through Tinyproxy
export HTTP_PROXY="http://127.0.0.1:8877"
export HTTPS_PROXY="http://127.0.0.1:8877"
export http_proxy="http://127.0.0.1:8877"
export https_proxy="http://127.0.0.1:8877"

# Bypass proxy for local services
export NO_PROXY="localhost,127.0.0.1"
export no_proxy="localhost,127.0.0.1"
```

Open a new terminal session after sourcing the profile.

### 3. Edit SSH config for github.com

Adding an SSH config replaces the earlier less safe strategy.

This section assumes you use SSH to connect with GitHub repo projects, and you
have registered a public key from the standard account on GitHub.com SSH key
settings.

Standard SSH operations (e.g., `git clone git@github.com:...`) do not automatically use shell `HTTP_PROXY` environment variables.

To route Git over SSH to GitHub through Tinyproxy from inside the sandbox, edit `~/.ssh/config` on the **sandbox account**:

```sshconfig
Host github.com
  User git
  ProxyCommand nc -X connect -x 127.0.0.1:8877 %h %p
```

**Why this is needed and how it works:**
* **HTTP CONNECT Tunneling:** `ProxyCommand nc -X connect ...` instructs SSH to tunnel its connection to GitHub through Tinyproxy via HTTP `CONNECT`.
* **No Sandbox DNS required:** SSH delegates hostname resolution for `github.com` to Tinyproxy outside the sandbox. You do not need to allow raw DNS (port 53) in Seatbelt.
* **No open Port 22 rule required:** Outbound traffic from the sandbox goes to `127.0.0.1:8877` (which is already permitted by Seatbelt), avoiding the need to open general outbound port 22 access.
* **Filtered by Tinyproxy:** SSH connections to GitHub are governed by your Tinyproxy `allowed_domains` list just like standard HTTP/HTTPS requests.

### 4. Testing

Verify the Seatbelt proxy filtering by prompting inside Qwen Code.

e.g.: `what's the output of this shell bash command? curl -I https://github.com`

| Test                       | Command                                 | Expected                |
|----------------------------|-----------------------------------------|-------------------------|
| Ollama (bypasses proxy)    | `curl http://127.0.0.1:11434/api/tags`  | Model list              |
| Allowed URL (via proxy)    | `curl -I https://github.com`            | `200 OK`                |
| Blocked URL                | `curl -I https://example.com`           | `403 Filtered`          |
| Direct IP (Seatbelt block) | `curl --noproxy '*' -I https://1.1.1.1` | `Connection failed (7)` |

Assuming you have registered a public key at Github.com SSH key settings, again
prompt in qwen:

1. Standard Test Command
   ```text
   What's the output of this shell bash command? ssh -T git@github.com
   ```
   Expected Result:
   ```console
   Hi <your-username>! You've successfully authenticated, but GitHub does not provide shell access.
   ```

2. Verbose Test Command (To see the proxy in action).
   To verify that SSH is actually tunneling through Tinyproxy via nc:
   ```text
   What's the output of this shell command? ssh -vvv -T git@github.com 2>&1 | grep -i "proxy"
   ```
   Expected Output:
   ```console
   debug1: Executing proxy command: nc -X connect -x 127.0.0.1:8877 github.com 22
   Authenticated to github.com (via proxy) using "publickey".
   ```
   This confirms SSH is delegating the connection to nc over 127.0.0.1:8877
   without making direct outbound connections.

---

## Troubleshooting

### Missing profile .sb

Each project must contain a sandbox profile (e.g.:
[sandbox-macos-permissive-proxied-ollama.sb](/.qwen/sandbox-macos-permissive-proxied-ollama.sb)
) file in a top-level `.qwen` folder.  A symlink to a single folder should work.
