# Secrets Management — SOPS + age

## Purpose
SOPS encrypts passwords and API tokens so encrypted files can be kept in Git. age manages the encryption keys. OpenTofu and Ansible use decrypted secrets when needed.

## Locations
- Git repository: `~/Documents/homelab/`
- SOPS configuration: `.sops.yaml`
- Encrypted Proxmox credentials: `secrets/proxmox.sops.env`
- Private age key (outside Git): `~/.config/sops/age/keys.txt`
- **Key backup location:** `[enter password-manager entry or encrypted-backup location]`

## Install and initial setup (once)
On Bazzite:

```bash
brew install sops age
install -d -m 700 ~/.config/sops/age
umask 077
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Back up `keys.txt` securely outside Git. Copy the **public** key (starting `age1`) into the root `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: ^secrets/.*\.sops\.(env|yaml)$
    age: age1REPLACE_WITH_YOUR_PUBLIC_KEY
```

Create `secrets/` if needed (`mkdir -p secrets`). Create or edit the encrypted Proxmox file with `EDITOR=nano sops edit secrets/proxmox.sops.env`. Store `PROXMOX_VE_ENDPOINT` and `PROXMOX_VE_API_TOKEN` in that file.

## Everyday commands
Run from the repository root:

```bash
# Edit credentials securely
EDITOR=nano sops edit secrets/proxmox.sops.env

# Use credentials for OpenTofu
sops exec-env secrets/proxmox.sops.env \
  'tofu -chdir=opentofu/proxmox plan'

# Check that decryption works without printing secrets
sops decrypt secrets/proxmox.sops.env >/dev/null && echo 'OK'
```

## Rebuild or move to a new machine
1. Install SOPS and age, then clone the Git repository.
2. Restore `keys.txt` from **the backup location recorded above** to `~/.config/sops/age/keys.txt`.
3. Run `chmod 600 ~/.config/sops/age/keys.txt`.
4. Test decryption with the command above.

Alternatively, add a new machine's age **public** key as a recipient and run `sops updatekeys` on each encrypted file using an existing authorised key.

## Git safety
- Commit `.sops.yaml` and **encrypted** `*.sops.env` / `*.sops.yaml` files.
- Never commit age private keys, plaintext passwords, decrypted files or OpenTofu state/plan files.
- In `.gitignore`, exclude ordinary `.env`, `*.tfvars`, `*.tfstate*` and `**/.terraform/`. If excluding `*.env`, add `!secrets/*.sops.env` so encrypted dotenv files can be committed.
- Check `git diff --cached` before committing.
- If an old key is compromised, removing it from SOPS does not protect old copies: rotate exposed credentials.

## References
- [SOPS documentation](https://getsops.io/docs/)
- [age](https://github.com/FiloSottile/age)
- [Proxmox provider](https://www.bpg.sh/docs/)
