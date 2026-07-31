**Generate a coding variant of `qwen3.6:35b-mlx`**

This guide shows how to derive a coding-tuned Ollama model named
`qwen3.6:35b-coding-mlx` from the base `qwen3.6:35b-mlx` tag by applying
the sampling parameters from `qwen3.6:35b-a3b-coding-nvfp4`.

- [Background](#background)
- [Steps](#steps)
  - [Create the coding model (admin account)](#create-the-coding-model-admin-account)
  - [Update Qwen Code to use coding model (sandbox account)](#update-qwen-code-to-use-coding-model-sandbox-account)
    - [Where `settings.json` lives](#where-settingsjson-lives)
    - [Editing the file](#editing-the-file)
    - [Save and test](#save-and-test)
- [References](#references)


## Background

An [Ollama Modelfile](https://docs.ollama.com/guide/modelfile) is a simple text
configuration file that controls how a model generates text. The key
directives are:

- `FROM` — which base model to use (the weights)
- `PARAMETER` — sampling settings such as `temperature`,
   `presence_penalty`
- `TEMPLATE` — the prompt format the model expects

The two tags `qwen3.6:35b-mlx` and `qwen3.6:35b-a3b-coding-nvfp4` ship the
**same weights** but with two different default sampling parameters. The
`-coding-nvfp4` tag is tuned for deterministic, low-variance code output.

The parameter deltas for the coding tag are:
- temperature 0.6 (vs 1.0)
- presence_penalty 0 (vs 1.5)

## Steps

### Create the coding model (admin account)

On the **admin** account where Ollama is installed, download the base model.
```sh
cd
ollama pull qwen3.6:35b-mlx
```

Then create the new tag:
```sh
# 1. Create a Modelfile (in the current working directory)
cat > Modelfile <<'EOF'
FROM qwen3.6:35b-mlx
PARAMETER temperature 0.6
PARAMETER presence_penalty 0
EOF

# 2. Create the new model tag from the Modelfile
ollama create qwen3.6:35b-coding-mlx -f Modelfile

# 3. Verify the two parameters were applied
ollama show qwen3.6:35b-coding-mlx --modelfile | sed '/LICENSE/q'

# 4. Delete the Modelfile
rm Modelfile
```

That's it. The new tag `qwen3.6:35b-coding-mlx` uses the same base weights
but the coding-specific sampling defaults.

---

### Update Qwen Code to use coding model (sandbox account)

The following steps assume you already initialized Qwen Code to use another model. If not, then skip this section and follow the
[setup in README](/README.md#setup-qwen-code) using Model ID
`qwen3.6:35b-coding-mlx` and you are then finished.

After creating the new model on the **admin** account, switch Qwen Code to use
it in the **sandbox** (standard) account by editing `settings.json`.

#### Where `settings.json` lives

There are two levels at which `settings.json` can be edited:

| Location | Path | Scope |
|---|---|---|
| **Project** | `.qwen/settings.json` | Only applies when `qwen` is launched from this project directory |
| **Home** | `~/.qwen/settings.json` | Applies to `qwen` in **all** project directories |

Both files can coexist. Values in the **project-level** file take precedence
over the **home-level** file when you are inside that project.

#### Editing the file

Open the file in `nano` (or `vim` / your editor of choice):

```sh
# For the project-level file (run from the project directory):
cd ~/src/your-project
nano .qwen/settings.json

# Or for the home-level file (from anywhere):
nano ~/.qwen/settings.json
```

Copy an entry for an existing model from the `modelProviders.openai` array,
then add a new entry with `id` and `name` referencing the new tag - keeping the same `baseURL`, `envKey`, and `generationConfig`.

<img src="/images/settings_model_arrays.png" alt="modelProviders.openai model arrays in settings.json" width="100%"/>

#### Save and test

1. Save the settings file and exit your editor.
2. Open Qwen Code from the same project directory:
   ```sh
   cd ~/src/my-project
   qwen
   ```
   Use the `/model` command to select `qwen3.6:35b-coding-mlx`.
3. Send a prompt to confirm the model responds.

---

## References

- [Ollama Modelfile docs](https://docs.ollama.com/modelfile)
- [Ollama qwen3.6 model tags](https://ollama.com/library/qwen3.6/tags)
- [Qwen Code model providers](https://qwenlm.github.io/qwen-code-docs/en/users/configuration/model-providers)
