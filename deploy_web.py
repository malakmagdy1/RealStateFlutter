import paramiko
import os

# Server details
host = "31.97.46.103"
username = "root"
password = "Iibrah@25722"
remote_path = "/var/www/aqarapp.co/"
local_file = r"C:\Users\B-Smart\AndroidStudioProjects\real\build\web_build.tar.gz"

# Create SSH client
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    print(f"Connecting to {host}...")
    ssh.connect(host, username=username, password=password)
    print("Connected!")

    # Upload file via SFTP
    sftp = ssh.open_sftp()
    print(f"Uploading {local_file} to {remote_path}...")
    sftp.put(local_file, remote_path + "web_build.tar.gz")
    print("Upload complete!")
    sftp.close()

    # Extract on server and move files from web subfolder to root
    print("Extracting files on server...")
    commands = f"""
    cd {remote_path} && \
    rm -rf assets canvaskit icons *.js *.json *.html *.png *.svg 2>/dev/null; \
    tar -xzf web_build.tar.gz && \
    rm web_build.tar.gz && \
    cp -r web/* . && \
    rm -rf web
    """
    stdin, stdout, stderr = ssh.exec_command(commands)
    exit_status = stdout.channel.recv_exit_status()
    if exit_status == 0:
        print("Extraction complete!")
    else:
        print(f"Extraction error: {stderr.read().decode()}")

    # List files to verify
    stdin, stdout, stderr = ssh.exec_command(f"ls -la {remote_path}")
    print("\nFiles on server:")
    print(stdout.read().decode())

except Exception as e:
    print(f"Error: {e}")
finally:
    ssh.close()
    print("Done!")
