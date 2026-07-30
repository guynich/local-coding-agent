**Proxy Setup — Tinyproxy + Seatbelt for Qwen Code**

This guide walks through setting up a lightweight local forward proxy outside
the sandbox to restrict Qwen Code's internet access.

- [1. Tinyproxy on the admin account](#1-tinyproxy-on-the-admin-account)
- [2. Seatbelt profile in the project](#2-seatbelt-profile-in-the-project)
- [3. Sandbox environment variables](#3-sandbox-environment-variables)
- [4. Testing](#4-testing)

## 1. Tinyproxy on the admin account

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

## 2. Seatbelt profile in the project

Copy the Qwen Code
[permissive-proxied profile](https://github.com/QwenLM/qwen-code/blob/main/packages/cli/src/utils/sandbox-macos-permissive-proxied.sb)
into your project's `.qwen` folder and add two lines for Ollama access and SSH access to any address:

```scheme
(allow network-outbound (remote tcp "localhost:11434"))
(allow network-outbound (remote tcp "*:22"))
```

> I added SSH access for git commands.  It would be safer to switch to
> https for git, and remove the second line.

The file should be named
`sandbox-macos-permissive-proxied-ollama.sb`.

## 3. Sandbox environment variables

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

## 4. Testing

Verify the Seatbelt proxy filtering by prompting inside Qwen Code.

e.g.: `what's the output of this command? url -I https://github.com`

| Test                       | Command                                 | Expected                |
|----------------------------|-----------------------------------------|-------------------------|
| Ollama (bypasses proxy)    | `curl http://127.0.0.1:11434/api/tags`  | Model list              |
| Allowed URL (via proxy)    | `curl -I https://github.com`            | `200 OK`                |
| Blocked URL                | `curl -I https://example.com`           | `403 Filtered`          |
| Direct IP (Seatbelt block) | `curl --noproxy '*' -I https://1.1.1.1` | `Connection failed (7)` |
