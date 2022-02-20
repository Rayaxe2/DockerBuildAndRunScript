# DockerBuildAndRunScript
The script nuilds ASP.NET website with dotnet, configures Docker's VM memory and processor limits, prunes dangling images, containers and unused networks (to clear some memory in the VM), builds a docker image and container (killing old containers before hand and rebuilding existing images instead of making a new one) and run the container in ports 8000 (for HTTP port 80) and 8001 (for HTTPS port 443), navigating to it's web path when it's up.

Before running it, in powershell, do the following 
 - Run "Set-ExecutionPolicy RemoteSigned" to give it permission to scripts locally.
 - Set the variables at the top of the script to something that make sense for your project
 - run the following in powershell:
  - cd [Your Project Path]
  - docker build -t [porject name] .
  - dotnet dev-certs https -ep $env:USERPROFILE\.aspnet\https\aspnetapp.pfx -p password
  - dotnet dev-certs https --trust

Change the script to set "$ProjectPath" variable to the root path of the razor page project you want to dockerize (where the docker file is) and change the "$WebSitePath" variable to the website URL you want it to navigate to when all the building and deploying is done.
In my case, I have it set to the URL of the IIS web application that I'm hosting with the PHP/legacy website files locally (which has the iframe page that references the docker website - make sure to set that iframe's "src" artibute to something like "https://localhost:8001/..." - I.E. The link to the docker container the script creates).


