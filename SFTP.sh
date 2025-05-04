#!/bin/bash

# Function to choose operation: upload or download
choose_operation() {
  echo "Secure File Sharing System"
  echo "-------------------------"
  echo "1. Upload file"
  echo "2. Download file"
  read -p "Enter option [1/2]: " operation_option

  case "$operation_option" in
    1) choose_encryption "upload" ;;
    2) download_file ;;
    *) echo "Invalid option."; exit 1 ;;
  esac
}

# Function to choose encryption/decryption type
choose_encryption() {
  operation=$1
  echo "Choose encryption type:"
  echo "1. Symmetric (AES-256-CBC with OpenSSL)"
  echo "2. Asymmetric (GPG)"
  read -p "Enter option [1/2]: " enc_option

  case "$enc_option" in
    1) if [ "$operation" == "upload" ]; then
         encrypt_symmetric
       else
         decrypt_symmetric
       fi ;;
    2) if [ "$operation" == "upload" ]; then
         encrypt_asymmetric
       else
         decrypt_asymmetric
       fi ;;
    *) echo "Invalid encryption option."; exit 1 ;;
  esac
}

# Function to encrypt file symmetrically with secure password handling
encrypt_symmetric() {
  read -p "Enter file to encrypt: " infile
  if [ ! -f "$infile" ]; then
    echo "Error: File does not exist."
    exit 1
  fi
  read -p "Enter output filename (e.g., $infile.enc): " outfile
  read -s -p "Enter password for encryption: " password
  echo
  tmpfile=$(mktemp)
  echo "$password" > "$tmpfile"
  openssl enc -aes-256-cbc -salt -in "$infile" -out "$outfile" -pass file:"$tmpfile"
  if [ $? -eq 0 ]; then
    echo "Encryption successful: $outfile created."
    rm "$tmpfile"
    choose_transfer "$outfile"
  else
    echo "Encryption failed."
    rm "$tmpfile"
    exit 1
  fi
}

# Function to encrypt file asymmetrically
encrypt_asymmetric() {
  read -p "Enter file to encrypt: " infile
  if [ ! -f "$infile" ]; then
    echo "Error: File does not exist."
    exit 1
  fi
  read -p "Enter GPG recipient (e.g., user@example.com or key ID): " recipient
  gpg --output "$infile.gpg" --encrypt --recipient "$recipient" "$infile"
  if [ $? -eq 0 ]; then
    echo "Encryption successful: $infile.gpg created."
    choose_transfer "$infile.gpg"
  else
    echo "Encryption failed. Ensure recipient's key is available."
    exit 1
  fi
}

# Function to choose transfer method
choose_transfer() {
  filename=$1
  echo "Choose transfer method:"
  echo "1. SCP (Secure Copy)"
  echo "2. RSYNC (Remote Sync)"
  read -p "Enter option [1/2]: " transfer_option
  read -p "Enter remote destination (user@host:/path): " destination

  case "$transfer_option" in
    1) scp "$filename" "$destination" ;;
    2) rsync -av "$filename" "$destination" ;;
    *) echo "Invalid transfer option."; exit 1 ;;
  esac

  if [ $? -eq 0 ]; then
    echo "File transferred successfully to $destination."
  else
    echo "File transfer failed. Check SSH configuration."
    exit 1
  fi
}

# Function to download file
download_file() {
  read -p "Enter remote file (e.g., user@host:/path/to/file): " remote_file
  read -p "Enter local filename to save: " local_file
  scp "$remote_file" "$local_file"
  if [ $? -eq 0 ]; then
    echo "File downloaded successfully as $local_file."
    choose_encryption "download"
  else
    echo "Download failed. Check remote path or SSH access."
    exit 1
  fi
}

# Function to decrypt file symmetrically
decrypt_symmetric() {
  read -p "Enter encrypted file: " encf
  if [ ! -f "$encf" ]; then
    echo "Error: File does not exist."
    exit 1
  fi
  read -p "Enter output filename: " outf
  read -s -p "Enter password for decryption: " password
  echo
  tmpfile=$(mktemp)
  echo "$password" > "$tmpfile"
  openssl enc -d -aes-256-cbc -in "$encf" -out "$outf" -pass file:"$tmpfile"
  if [ $? -eq 0 ]; then
    echo "Decryption successful: $outf created."
    rm "$tmpfile"
  else
    echo "Decryption failed. Wrong password or corrupted file."
    rm "$tmpfile"
    exit 1
  fi
}

# Function to decrypt file asymmetrically
decrypt_asymmetric() {
  read -p "Enter .gpg file: " gpgf
  if [ ! -f "$gpgf" ]; then
    echo "Error: File does not exist."
    exit 1
  fi
  gpg --output "${gpgf%.gpg}" --decrypt "$gpgf"
  if [ $? -eq 0 ]; then
    echo "Decryption successful: ${gpgf%.gpg} created."
  else
    echo "Decryption failed. Check GPG key or passphrase."
    exit 1
  fi
}

# Start the script
choose_operation