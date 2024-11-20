# Use a lightweight base image
FROM mcr.microsoft.com/powershell:latest

# Set the working directory
WORKDIR /scripts

# Copy your PowerShell script into the container
COPY main.ps1 .

# Execute the PowerShell script
CMD ["pwsh", "pwd ; dir"]

### End of File
