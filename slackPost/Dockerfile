# Use a lightweight base image
FROM mcr.microsoft.com/powershell:latest

# Set the working directory

# Copy your PowerShell script into the container
COPY main.ps1 .

# Execute the PowerShell script
CMD ["pwsh", "./slackPost/main.ps1"]

### End of File
