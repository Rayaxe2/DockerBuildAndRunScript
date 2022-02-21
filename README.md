# DockerBuildAndRunScript
The script navigates to your ASP.NET website's project directory, checks to see you have HTTPS certificates configured (if not, sets up the certificates), configures Docker's VM memory and processor limits (by creating a ./wslconfig file in your user drectory - setting the limit to 6gb RAM and 4 processors - you can edit these limits by editing the file), builds the project with dotnet, prunes dangling images, containers and unused networks (to clear some memory in the VM), builds a docker image and container (killing old containers before hand and rebuilding existing images instead of making a new one), runs the container in ports 8000 (for HTTP port 80) and 8001 (for HTTPS port 443) and then navigates to the provided web path/URL with your PC's dafault browser.

Before running it, in powershell, do the following 
 - Run "Set-ExecutionPolicy RemoteSigned" to give it permission to scripts locally.
 - Set the variables at the top of the script to something that make sense for your project
   - Change the script to set "$ProjectPath" variable to the root path of the razor page project you want to dockerize (where the docker file is) and change the "$WebSitePath" variable to the website URL you want it to navigate to when all the building and deploying is done.
   - In my case, I have it set to the URL of the IIS web application that I'm hosting with the PHP/legacy website files locally (which has the iframe page that references the docker website - make sure to set that iframe's "src" artibute to something like "https://localhost:8001/..." - I.E. The link to the docker container the script creates).

If the Docker VM is consuming too much memory, you can free up memory by executing the following command in powershell:
```
docker system prune -f
```
This is commented out in the scipt as it can make rebuilding the images slow (likely because it deletes the Docker VM's cache)
