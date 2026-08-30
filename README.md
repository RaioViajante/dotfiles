# macOS dotfiles

Ambiente de desenvolvimento macOS explícito, rápido e reproduzível. O repositório usa chezmoi para gerenciar Zsh, Git, Starship e bootstrap de ferramentas sem frameworks grandes de shell e sem armazenar credenciais.

## Ferramentas

- macOS, Zsh e Homebrew
- chezmoi, Git e GitHub CLI
- Starship, zoxide, fzf, eza, bat e ripgrep
- Node.js 24, pnpm e Angular CLI
- Java 21 LTS e Maven
- Docker, Podman, VS Code e IntelliJ IDEA

Angular CLI e Codex CLI atualmente são pacotes npm globais e não são instalados automaticamente pelo Brewfile. Podman também não é instalado pelo Brewfile porque a instalação atual não veio do Homebrew.

## Estrutura

```text
.
├── Brewfile
├── dot_zshrc
├── dot_zprofile
├── dot_gitconfig
├── dot_config/
│   ├── git/ignore
│   ├── starship.toml
│   └── zsh/
│       ├── aliases.zsh
│       ├── completion.zsh
│       ├── dev.zsh
│       ├── functions.zsh
│       ├── options.zsh
│       ├── paths.zsh
│       └── tools.zsh
├── run_once_before_10-install-homebrew.sh.tmpl
├── run_onchange_before_20-brew-bundle.sh.tmpl
├── run_onchange_after_30-local-setup.sh.tmpl
└── scripts/
    ├── check-secrets.sh
    └── macos-defaults.sh
```

Arquivos com prefixo `dot_` são aplicados ao home pelo chezmoi. `README.md`, `Brewfile` e `scripts/` ficam apenas no source state por meio de `.chezmoiignore`.

## Validação automática

O workflow `.github/workflows/validate.yml` roda em macOS a cada push e pull request. Ele verifica estrutura obrigatória, sintaxe Bash/Zsh/Git/Brewfile, secrets, caminhos específicos de máquina e uma aplicação isolada do chezmoi em diretório temporário.

## Requisitos

- Mac com acesso à internet
- usuário com permissão para instalar Homebrew
- Command Line Tools do Xcode quando solicitado pelo instalador do Homebrew
- conta GitHub para clonar o repositório e configurar Git/SSH

## Instalação em um Mac novo

O instalador standalone do chezmoi permite iniciar sem Homebrew:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply RaioViajante
```

Se o chezmoi já estiver instalado:

```sh
chezmoi init --apply RaioViajante
```

Durante o primeiro apply, os scripts:

1. instalam Homebrew se estiver ausente;
2. executam o Brewfile;
3. aplicam os dotfiles;
4. criam diretórios locais e um `local.gitconfig` vazio quando necessário.

## Git local

O arquivo versionado `dot_gitconfig` contém somente comportamento portável. Nome e e-mail devem ser configurados por máquina em `~/.config/git/local.gitconfig`:

```gitconfig
[user]
    name = SEU_NOME
    email = SEU_EMAIL_VERIFICADO_OU_NOREPLY
```

Confirme a origem:

```sh
git config --global --includes --show-origin --get-regexp '^user\.'
```

`~/.config/git/local.gitconfig` não é copiado para o source state e nunca deve ser commitado.

## GitHub CLI e SSH por máquina

Autenticação e chaves SSH não são restauradas pelos dotfiles. Em cada Mac, faça login pelo navegador:

```sh
gh auth login --hostname github.com --web --git-protocol ssh --skip-ssh-key
gh auth status
```

Se ainda não houver uma chave dedicada, crie uma com passphrase e registre apenas a pública:

```sh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_raioviajante
gh ssh-key add ~/.ssh/id_ed25519_raioviajante.pub --type authentication --title "macOS development"
```

Crie localmente `~/.ssh/config`, com permissão `600`:

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_raioviajante
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
```

Valide com `ssh -T git@github.com`. Nem o SSH config, nem as chaves pública/privada, nem o keyring do GitHub CLI fazem parte deste repositório.

Para recuperar os CLIs npm globais usados neste ambiente, instale-os conscientemente após o Node estar disponível:

```sh
npm install --global @angular/cli @openai/codex
```

## Uso do chezmoi

Revisar e aplicar alterações recebidas:

```sh
chezmoi diff
chezmoi apply
chezmoi update
```

`chezmoi update` atualiza o repositório fonte e aplica as mudanças. Para aplicar configurações sem executar o Brewfile naquele ciclo:

```sh
DOTFILES_SKIP_BREW_BUNDLE=1 chezmoi apply
```

Editar uma configuração gerenciada:

```sh
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply
```

Adicionar uma nova configuração:

```sh
chezmoi add ~/.config/ferramenta/config
chezmoi cd
./scripts/check-secrets.sh
git diff --check
```

Nunca adicione diretórios inteiros como `.ssh`, `.docker`, `.codex` ou `.config/gh`.

## Brewfile

O Brewfile contém somente ferramentas diretas e aplicativos úteis para restaurar o ambiente. Dependências transitivas são resolvidas pelo Homebrew. O script `run_onchange_before_20-brew-bundle.sh.tmpl` volta a executar `brew bundle` somente quando o conteúdo do Brewfile muda.

Para verificar sem instalar:

```sh
brew bundle check --file="$(chezmoi source-path)/Brewfile"
```

## Secrets

Nunca são gerenciados ou copiados para o source state:

- chaves SSH públicas ou privadas;
- tokens e credenciais do GitHub CLI;
- `.env` e API keys;
- arquivos de autenticação do Codex, Docker e GitHub CLI;
- identidade Git local;
- cookies, históricos, caches e keyrings.

`.gitignore` e `.chezmoiignore` são apenas proteção complementar. Execute antes de cada commit:

```sh
./scripts/check-secrets.sh
git diff --check
git status --short
```

## macOS defaults

Os defaults são conservadores e opt-in:

```sh
./scripts/macos-defaults.sh
```

O script mostra extensões e barras de caminho/status, expande diálogos e evita `.DS_Store` em volumes externos. Não altera aparência, wallpaper ou segurança.

## Reverter ou deixar de gerenciar

Revise primeiro com `chezmoi diff`. Para abandonar uma edição ainda não aplicada, restaure o arquivo no repositório Git. Para deixar de gerenciar um arquivo sem apagá-lo do home:

```sh
chezmoi forget CAMINHO
```

Revise o diff antes de commit ou apply.
