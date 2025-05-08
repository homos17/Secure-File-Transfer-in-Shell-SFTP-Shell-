#!/bin/bash

# Function to choose operation: upload or download
choose_operation() {
    operation=$(zenity --list --title="Secure File Sharing System" \
                       --text="Choose operation:" \
                       --column="Key" --column="Operation" --hide-column=1 \
                       1 "Upload file" 2 "Download file")
    if [ -z "$operation" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    case "$operation" in
        1) choose_encryption "upload" ;;
        2) download_file ;;
        *) zenity --error --text="Invalid option."; exit 1 ;;
    esac
}

# Function to choose encryption/decryption type
choose_encryption() {
    operation=$1
    enc_option=$(zenity --list --title="Encryption Type" \
                        --text="Choose encryption type:" \
                        --column="Key" --column="Type" --hide-column=1 \
                        1 "Symmetric (AES-256-CBC with OpenSSL)" 2 "Asymmetric (GPG)")
    if [ -z "$enc_option" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    case "$enc_option" in
        1) if [ "$operation" == "upload" ]; then
               encrypt_symmetric
           else
               decrypt_symmetric "$file_to_decrypt"
           fi ;;
        2) if [ "$operation" == "upload" ]; then
               encrypt_asymmetric
           else
               decrypt_asymmetric "$file_to_decrypt"
           fi ;;
        *) zenity --error --text="Invalid encryption option."; exit 1 ;;
    esac
}

# Function to encrypt file symmetrically
encrypt_symmetric() {
    infile=$(zenity --file-selection --title="Select file to encrypt")
    if [ -z "$infile" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi
    if [ ! -f "$infile" ]; then
        zenity --error --text="Error: File does not exist."
        exit 1
    fi

    outfile=$(zenity --file-selection --save --title="Save encrypted file as" \
                     --filename="$infile.enc")
    if [ -z "$outfile" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    password=$(zenity --password --title="Enter password for encryption")
    if [ -z "$password" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    tmpfile=$(mktemp)
    echo "$password" > "$tmpfile"
    openssl enc -aes-256-cbc -salt -in "$infile" -out "$outfile" -pass file:"$tmpfile"
    if [ $? -eq 0 ]; then
        zenity --info --text="Encryption successful: $outfile created."
        rm "$tmpfile"
        choose_transfer "$outfile"
    else
        zenity --error --text="Encryption failed."
        rm "$tmpfile"
        exit 1
    fi
}

# Function to encrypt file asymmetrically
encrypt_asymmetric() {
    infile=$(zenity --file-selection --title="Select file to encrypt")
    if [ -z "$infile" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi
    if [ ! -f "$infile" ]; then
        zenity --error --text="Error: File does not exist."
        exit 1
    fi

    recipient=$(zenity --entry --title="GPG Recipient" \
                       --text="Enter GPG recipient (e.g., user@example.com or key ID):")
    if [ -z "$recipient" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    outfile="$infile.gpg"
    gpg --output "$outfile" --encrypt --recipient "$recipient" "$infile"
    if [ $? -eq 0 ]; then
        zenity --info --text="Encryption successful: $outfile created."
        choose_transfer "$outfile"
    else
        zenity --error --text="Encryption failed. Ensure recipient's key is available."
        exit 1
    fi
}

# Function to choose transfer method
choose_transfer() {
    filename=$1
    transfer_option=$(zenity --list --title="Transfer Method" \
                             --text="Choose transfer method:" \
                             --column="Key" --column="Method" --hide-column=1 \
                             1 "SCP (Secure Copy)" 2 "RSYNC (Remote Sync)")
    if [ -z "$transfer_option" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    destination=$(zenity --entry --title="Remote Destination" \
                         --text="Enter remote destination (user@host:/path):")
    if [ -z "$destination" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    case "$transfer_option" in
        1) scp "$filename" "$destination" ;;
        2) rsync -av "$filename" "$destination" ;;
        *) zenity --error --text="Invalid transfer option."; exit 1 ;;
    esac

    if [ $? -eq 0 ]; then
        zenity --info --text="File transferred successfully to $destination."
    else
        zenity --error --text="File transfer failed. Check SSH configuration."
        exit 1
    fi
}

# Function to download file
download_file() {
    remote_file=$(zenity --entry --title="Remote File" \
                         --text="Enter remote file (e.g., user@host:/path/to/file):")
    if [ -z "$remote_file" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    local_file=$(zenity --file-selection --save --title="Save downloaded file as")
    if [ -z "$local_file" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    scp "$remote_file" "$local_file"
    if [ $? -eq 0 ]; then
        zenity --info --text="File downloaded successfully as $local_file."
        if zenity --question --text="Do you want to decrypt the downloaded file?"; then
            file_to_decrypt="$local_file"
            choose_encryption "download"
        fi
    else
        zenity --error --text="Download failed. Check remote path or SSH access."
        exit 1
    fi
}

# Function to decrypt file symmetrically
decrypt_symmetric() {
    encf=$1
    if [ ! -f "$encf" ]; then
        zenity --error --text="Error: File does not exist."
        exit 1
    fi

    outf=$(zenity --file-selection --save --title="Save decrypted file as" \
                  --filename="${encf%.enc}")
    if [ -z "$outf" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    password=$(zenity --password --title="Enter password for decryption")
    if [ -z "$password" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    tmpfile=$(mktemp)
    echo "$password" > "$tmpfile"
    openssl enc -d -aes-256-cbc -in "$encf" -out "$outf" -pass file:"$tmpfile"
    if [ $? -eq 0 ]; then
        zenity --info --text="Decryption successful: $outf created."
        rm "$tmpfile"
    else
        zenity --error --text="Decryption failed. Wrong password or corrupted file."
        rm "$tmpfile"
        exit 1
    fi
}

# Function to decrypt file asymmetrically
decrypt_asymmetric() {
    gpgf=$1
    if [ ! -f "$gpgf" ]; then
        zenity --error --text="Error: File does not exist."
        exit 1
    fi

    outf=$(zenity --file-selection --save --title="Save decrypted file as" \
                  --filename="${gpgf%.gpg}")
    if [ -z "$outf" ]; then
        zenity --error --text="Operation cancelled."
        exit 1
    fi

    gpg --output "$outf" --decrypt "$gpgf"
    if [ $? -eq 0 ]; then
        zenity --info --text="Decryption successful: $outf created."
    else
        zenity --error --text="Decryption failed. Check GPG key or passphrase."
        exit 1
    fi
}

# Start the script
choose_operation