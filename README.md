# Minecraft Plugin Deployment Script

This PowerShell script automates the process of deploying a Minecraft plugin to a remote Crafty server. It performs the following steps:
1. Detects the path to Gradle if not specified.
2. Updates the version number in the `build.gradle` file.
3. Builds the project using Gradle.
4. Cleans up old plugin files on the remote server.
5. Deploys the newly built plugin to the remote server.
6. Restarts the Minecraft server (optional, if added).

## Prerequisites

- **Gradle**: Ensure Gradle is installed on your system. The script can auto-detect Gradle if it's in your system's PATH.
- **PowerShell**: This script is designed to run in PowerShell.
- **SSH Access**: SSH must be configured properly for communication with the remote server. You need to provide SSH credentials during script execution.

## Configuration

Before running the script, ensure the following configuration parameters are correctly set:

- **`gradlePath`**: The path to the `gradle.bat` file. If not provided, the script will attempt to auto-detect it.
- **`projectDir`**: The path to your project's root directory.
- **`buildGradlePath`**: The path to your `build.gradle` file.
- **`sshUser`**: SSH username for the remote server.
- **`sshServer`**: The hostname or IP address of the remote server.
- **`remoteCraftyServerPath`**: The base path on the remote server where Crafty is installed.
- **`remoteServerId`**: The unique identifier for your Minecraft server on the remote Crafty server.
- **`buildLibsPath`**: The path to the directory where Gradle outputs the built JAR files.

## Important Warnings

- **`build/libs` Folder**: This folder will be cleared before deploying new builds. Ensure no important files are left in this directory before running the script.
- **`plugins` Folder**: The `plugins` folder on the remote server will be cleared before deploying new files. Ensure no important plugins are lost.
- **Versioning**: Make sure to manually update the patch version in the `build.gradle` file before running the script. The script only increments the patch version automatically.
- **SSH Credentials**: The script will prompt for the SSH password twice:
  1. During the cleanup of old files.
  2. During the deployment of new files.

## Usage

1. **Prepare the Script**: Save the script as `Deploy-Plugin.ps1` on your local machine.

2. **Run the Script**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "Deploy-Plugin.ps1" -gradlePath "path\to\gradle.bat" -projectDir "path\to\project" -buildGradlePath "path\to\build.gradle" -sshUser "sshUser" -sshServer "sshServer" -remoteCraftyServerPath "/opt/docker/crafty/servers" -remoteServerId "remoteServerId" -buildLibsPath "path\to\build\libs"
   ```

3. **Script Execution**:
   - The script will first attempt to auto-detect the Gradle path if not specified.
   - It will then update the version in the `build.gradle` file and build the project.
   - Old plugin files on the remote server will be cleared.
   - The newly built JAR file will be deployed to the remote server.
   - The script will then prompt you for the SSH password.

## Script Details

### Auto-Detect Gradle Path

If the `gradlePath` is not provided, the script will attempt to detect it automatically using the system’s PATH.

### Update Version

The script updates the version in `build.gradle` by incrementing the patch version number. Ensure that your versioning format is consistent.

### Build Gradle

The script executes Gradle build commands from the project directory.

### SSH Connection

The `Establish-SSHConnection` function sets up the SSH connection and adds the server to known hosts if not already present.

### Cleanup Old Files

The `Cleanup-OldFiles` function removes old plugin files from the remote server. It uses SSH to execute commands on the remote server.

### Deploy New Files

The `Deploy-NewFiles` function uploads the newly built JAR file to the remote server using SCP. You will be prompted to enter your SSH password.

### Restart Minecraft Server 

Restart the server manually, you might stop it before starting the script and start it after its done.

## Troubleshooting

- **Gradle Not Found**: Ensure Gradle is installed and available in the system PATH. Provide the correct path to `gradle.bat` if auto-detection fails.
- **SSH Connection Issues**: Verify SSH credentials and network connectivity to the remote server.

For further assistance, consult the Gradle and SSH documentation or seek help from your system administrator.
