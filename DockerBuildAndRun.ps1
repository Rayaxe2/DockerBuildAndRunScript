$ProjectPath = "C:\..." #Project path
$ImageName = "..." #Names of image you want to build/rebuild - the name must be all lowercase!
$ContinerName = "..." #Name for container
$WebSitePath = "https://localhost/..." #Home.php #Website Path you want to navigate to when the applucation is build and containerised

$PostContinerKillSleepDuration = 2 #Sets the amount of time the script should sleep after killing the container and proceeding
$PostErrorSleepDutation = 2 #Sets the amount of time the script should sleep after and error occurs and the script ends as a result
$PostScriptSuccessSleepDuration = 1 #Sets the amount of time the script should sleep after the script succesfully finishes executing

echo ""
echo "/==============\"
echo "Starting Script"
echo "\==============/"
echo ""

#Checks to see if the variables in line 1 to 4 have been set to something outside of the default
echo "> Checking If Script Varables Have Been Set..."
if(($ProjectPath -eq "C:\...") -or ($ImageName -eq "...") -or ($ContinerName -eq "...") -or ($WebSitePath -eq "https://localhost/...")) {
    echo "> Some Or All The Variables At Line 1 to 4 Of The Script Have Not Been Set! Please Edit The Script And Changes These Values From The Default!"
    echo "!!!!!!!!!!!!!!!"
    echo "Aborting Script"
    echo "!!!!!!!!!!!!!!!"
    Start-Sleep -s $PostErrorSleepDutation
    Exit
}
echo "> Variables Were Set"
echo ">> Done"
echo ""

echo "> Checking If .wslconfig File Exists In User Directory"
if([System.IO.File]::Exists($env:USERPROFILE + '\.wslconfig')) #Checks if there is a file call .wslconfig in the user directory
{
    echo "> '.wslconfig' File Found In $env:USERPROFILE Directory"
}
else 
{
    #Creates new .wslconfig file (if one does not exist), limiting the VM (vmmem) to 6gb and 4 processors. You can edit the file in notepad to increase this.
    New-Item ($env:USERPROFILE + '\.wslconfig')
    Set-Content ($env:USERPROFILE + '\.wslconfig') "[wsl2]`nmemory=6GB`nprocessors=4"
    echo "> Created .wslconfig File - Limiting The Memory To 6gb, And Assigning 4 Processors"
}
echo ">> Done"
echo ""

echo "> Changing To Project Directory..."
cd $ProjectPath 
if ($?)
{
    echo ">> Done"
    echo ""
    echo "> Building Project..."
    dotnet build #Builds project in DotNet
    if ($?)
    {
        echo ">Finished Building"
        echo ">> Done"
        echo ""
        echo "> Killing Old Container..."
        docker kill $ContinerName #Kills old container before rebuilding image
        if ($?)
        {
            echo ">> Done"
            echo ""
        }
        else {
            echo "> WARNING: COULD NOT KILL OLD CONTAINER. ASSUMING IT DOES NOT EXIST AND CONTINUING SCRIPT"
            echo ""
        }
        Start-Sleep -s $PostContinerKillSleepDuration #Gives sometime for the old container to die
        if($(docker images -f ???dangling=true??? -q).count -gt 0) { #Checks if there are dangling images
            echo ">Deleting Dangling Docker Images..."
            echo ">Deleted Images:"
            echo "================"
            docker rmi $(docker images -f ???dangling=true??? -q) #Removes dangling images
            if ($?)
            {
                echo ">> Done"
                echo ""
            }
            else {
                echo "> WARNING: AN ERROR OCCURRED WHILE PRUNING OLD IMAGES. PROCEEDING WITH EXECUTION REGARDLESS!"
                echo ">> Done"
                echo ""
            }
        }

        #Uncomment and use if you want to prune the system and free memory in the linux virutal machine docker runs on#
        #However, not that this could make building the image take a bit longer (likely because you may be clearing cached data that makes it fast)

        #docker system prune -f #--filter "until=24h" --filter "label=nameOfItemsToFilter" #The filter and until part is optional too, it lets you pick specific data to prune based on when they were made from now and their labels

        echo ">Pruning Dangling Images, Containers and Networks To Free Up Space In Linux Environment (WSL)..."
        echo ">Pruning Status:"
        echo "================"
        docker image prune -f #Prunes dangling images
        if ($?)
        {
            echo "--Images Pruned"
        }
        else {
            echo "> WARNING: AN ERROR OCCURRED WHILE PRUNING DOCKER IMAGES. PROCEEDING WITH EXECUTION REGARDLESS!"
        }

        docker container prune -f #Prunes dangling containers
        if ($?)
        {
            echo "--Containers Pruned"
        }
        else {
            echo "> WARNING: AN ERROR OCCURRED WHILE PRUNING DOCKER CONTAINERS. PROCEEDING WITH EXECUTION REGARDLESS!"
        }

        docker network prune -f #Prunes unused network
        if ($?)
        {
            echo "--Networks Pruned"
        }
        else 
        {
            echo "> WARNING: AN ERROR OCCURRED WHILE PRUNING DOCKER NETWORKS. PROCEEDING WITH EXECUTION REGARDLESS!"
        }
        echo ">> Done"
        echo ""

        echo "> Building Docker Image..."
        docker build -t $ImageName . #Builds image using the dockerfile in the current directory (the one specified before - hence the dot)
        if ($?)
        {
            echo ">> Done"
            echo ""
        }
        else {
            echo "> WARNING: AN ERROR OCCURRED WHILE BUILDING THE DOCKER IMAGE. PROCEEDING WITH EXECUTION OF SCRIPT AND ASSUMING IT DID NOT PREVENT THE CREATION OF THE IMAGE"
            echo ">> Done"
            echo ""
        }
        #Checks to see if you have HTTPS certificates set up in dotnet, and sets them up if they're not
        echo "> Checking If HTTPS Certificates Have Been Set Up..."
        if((dotnet dev-certs https --check) -eq ""){
            echo "> No HTTPS Certificats Found For Project"
            echo "> Setting Up HTTPS Certificates..."
            dotnet dev-certs https -ep $env:USERPROFILE\.aspnet\https\aspnetapp.pfx -p password
            dotnet dev-certs https --trust
            dotnet dev-certs https --check
            echo ">> Done"
            echo ""
        }
        else {
            echo "> Certificate Found"
            echo ">> Done"
            echo ""
        }

        echo "> Creating And Running Docker Container Form $ImageName Image..."
        echo "Image Referance:"
        echo "================"
        #Runs a container made from the image build above - setting it to the container name, running it on ports 8000 for HTTP and 8001 for HTTPs
        docker run -d --name $ContinerName --rm -it -p 8000:80 -p 8001:443 -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT=8001 -e ASPNETCORE_Kestrel__Certificates__Default__Password="password" -e ASPNETCORE_Kestrel__Certificates__Default__Path=/https/aspnetapp.pfx -v $env:USERPROFILE\.aspnet\https:/https/ $ImageName
        if ($?)
        {
            echo ">> Done"
            echo ""
            echo "> Navigating To '$WebSitePath'..."
            Start-Sleep -s 2
            Start-Process $WebSitePath #Opens the provided webpath in your default browser is all goes well
            if ($?)
            {            
                echo ">> Done"
                echo ""
                echo "======================================="
                echo "script Successfully Finished Executing!"
                echo "======================================="
                echo ""
                docker ps
                Start-Sleep -s $PostScriptSuccessSleepDuration

            }
            else {
                echo "> ERROR: COULD NOT NAVIGATE TO '$WebSitePath', PLEASE ATTEMPT TO NAVIGATE TO THE WEBSITE MANAULLY"
                echo "================"
                echo "Script Finished."
                echo "================"
                Start-Sleep -s $PostScriptSuccessSleepDuration
            }
        }
        else {
            echo "> ERROR: COULD NOT CREATE A CONTAINER FROM THE DOCKER IMAGE"
            echo "!!!!!!!!!!!!!!!"
            echo "Aborting Script"
            echo "!!!!!!!!!!!!!!!"
            Start-Sleep -s $PostErrorSleepDutation
        }
        
    }
    else {
        echo "> ERROR: COULD NOT SUCCESSFULLY BUILD THE APPLICATION, PLEASE BUILD IN VISUAL STUDIOS AND CHECK FOR BUILD ERRORS"
        echo "!!!!!!!!!!!!!!!"
        echo "Aborting Script"
        echo "!!!!!!!!!!!!!!!"
        Start-Sleep -s $PostErrorSleepDutation
    }
} 
else {
    echo "> ERROR: UNABLE TO FIND OR CHANGE TO THE DIRECTORY '$ProjectPath'"
    echo "!!!!!!!!!!!!!!!"
    echo "Aborting Script"
    echo "!!!!!!!!!!!!!!!"
    Start-Sleep -s $PostErrorSleepDutation
}
