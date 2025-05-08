# 🔐 Secure File Transfer in Shell (SFTP-Shell)

A secure file transfer system written in pure Bash that leverages industry-standard encryption tools (OpenSSL & GPG) to ensure files are safely shared over insecure networks using SCP or RSYNC over SSH.

---

## 🎯 Project Goal

This project aims to provide a **minimal, secure, and easy-to-use** command-line tool to:

- Encrypt sensitive files locally before sending them.
- Transfer files securely using existing encrypted channels (SCP/RSYNC via SSH).
- Allow decryption only by authorized users (via password or public key).
- Be lightweight and run on most UNIX-based systems without dependencies on heavy software.

---
## Team Members

- Mohamed Wael 
- Eslaam Ibrahim 
- Malak Ali 

## 🔒 Security Approach

| Technique        | Tool Used  | Notes |
|------------------|------------|-------|
| Symmetric Encryption | OpenSSL (AES-256-CBC) | User-provided password; fast and simple. |
| Asymmetric Encryption | GPG | Secure key-based encryption; no password sharing. |
| Transfer Layer | SCP / RSYNC | Uses SSH; encrypted and authenticated. |

All encryption happens **locally**, so no plain data is sent over the network. Passwords are not stored, only used in memory temporarily.

---

## 📦 Features

- 📁 Upload or download mode
- 🔐 Two encryption options:
  - AES-256 (OpenSSL)
  - GPG (PGP standard)
- 📤 Transfer via:
  - `scp` (simple & secure)
  - `rsync` (efficient for large or repeated transfers)
- ✅ Error checking at each step
- 🧠 Modular functions for easy customization
- 🧪 Temporary password handling using `mktemp`

---

## 📚 Use Cases

- ✅ System admins sending sensitive configuration files.
- ✅ Developers deploying encrypted backups.
- ✅ Students learning about secure file sharing and Bash scripting.
- ✅ Transferring academic or medical documents securely.

## ⚙️ How It Works (Internal Flow)

```plaintext
Step 1: User chooses upload or download
Step 2: User selects encryption method (AES or GPG)
Step 3: Script encrypts (upload) or decrypts (download) the file
Step 4: File is transferred via SCP or RSYNC
Step 5: User is notified of success/failure
```

## 🧰 Requirements

Make sure you have these tools installed:

- bash
- openssl
- gpg
- scp
- rsync
- ssh
---
Install using:

```bash
sudo apt install openssh-client rsync openssl gnupg
```

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-username/secure-file-transfer-shell.git
cd secure-file-transfer-shell
```

### 2. Make the script executable

```bash
chmod +x SFTP.sh
```

### 3. Run the script

```bash
./SFTP.sh
```

Follow the menu instructions interactively.

---

## 🧪 Example: Uploading with AES

```bash
./SFTP.sh
```

Follow prompts:

- Choose option 1 (Upload)
- Choose AES encryption
- Enter file name
- Choose transfer method
- Enter destination (e.g. user@host:/path)

---

## 🛡️ GPG Encryption Guide

To use asymmetric encryption with GPG, follow these steps:

### Generate your key:

```bash
gpg --full-generate-key
```

### Share your public key:

```bash
gpg --armor --export you@example.com
```

### Import a recipient key:

```bash
gpg --import recipient-key.asc
```

## 🤝 Contributions

Feel free to fork this repo, suggest features, or submit pull requests!

