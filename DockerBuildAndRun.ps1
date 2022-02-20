echo ""
echo "> Starting Script"
echo ""
echo "> Checking If .wslconfig File Exists In User Directory"
if([System.IO.File]::Exists($env:USERPROFILE + '\.wslconfig')) #Checks if there is a file call .wslconfig in the user directory
{
    echo "> .wslconfig found in $env:USERPROFILE directory"
}
else 
{
    #Creates new .wslconfig file (if one does not exist), limiting the VM (vmmem) to 6gb and 4 processors. You can edit the file in notepad to increase this.
    New-Item ($env:USERPROFILE + '\.wslconfig')
    Set-Content ($env:USERPROFILE + '\.wslconfig') "[wsl2]`nmemory=6GB`nprocessors=4"
    echo "> Created .wslconfig File - Limiting The Memory To 6gb, And Assigning 4 Processors"
}
echo "> Done"
echo ""

echo "> Changing to project directory..."
$ProjectPath = "..." #Project path
$WebSitePath = "..." #Home.php #Website Path you want to navigate to when the applucation is build and containerised
$ContinerName = "..." #Name for container
$PostContinerKillSleepDuration = 1 #Set the amount of time the script should sleep after killing the container and proceeding
$ImageName = "..." #Names of image you want to build/rebuild
cd $ProjectPath 
if ($?)
{
    echo "> Done"
    echo ""
    echo "> Building Project..."
    dotnet build #Builds project in DotNet
    if ($?)
    {
        echo "Finished Building"
        echo "> Done"
        echo ""
        echo "> Killing old container..."
        docker kill $ContinerName #Kills old container before rebuilding image
        if ($?)
        {
            echo "> Done"
            echo ""
        }
        else {
            echo "> WARNING: COULD NOT KILL OLD CONTAINER. ASSUMING IT DOES NOT EXIST AND CONTINUING SCRIPT"
            echo ""
        }
        Start-Sleep -s $PostContinerKillSleepDuration #Gives sometime for the old container to die
        if($(docker images -f “dangling=true” -q).count -gt 0) { #Checks if there are dangling images
            echo ">Deleting Dangling Docker Images..."
            echo ">Deleted Images:"
            echo "================"
            docker rmi $(docker images -f “dangling=true” -q) #Removes dangling images
            if ($?)
            {
                echo "> Done"
                echo ""
            }
            else {
                echo "> WARNING: AN ERROR OCCURRED WHILE PRUNING OLD IMAGES. PROCEEDING WITH EXECUTION REGARDLESS!"
                echo "> Done"
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
        echo "> Done"
        echo ""

        echo "> Building Docker Image..."
        docker build -t $ImageName . #Builds image using the dockerfile in the current directory (the one specified before - hence the dot)
        if ($?)
        {
            echo "> Done"
            echo ""
        }
        else {
            echo "> WARNING: AN ERROR OCCURRED WHILE BUILDING THE DOCKER IMAGE. PROCEEDING WITH EXECUTION OF SCRIPT AND ASSUMING IT DID NOT PREVENT THE CREATION OF THE IMAGE"
            echo "> Done"
            echo ""
        }
        #You only need to run the bellow once - to set up the HTTPS certificates

        #echo "> Setting up HTTPS certificates"
        #dotnet dev-certs https -ep $env:USERPROFILE\.aspnet\https\aspnetapp.pfx -p password
        #dotnet dev-certs https --trust
        #echo "> Done"

        echo "> Creating and running docker container for image..."
        echo "Image Referance:"
        #Runs a container made from the image build above - setting it to the container name, running it on ports 8000 for HTTP and 8001 for HTTPs
        docker run -d --name $ContinerName --rm -it -p 8000:80 -p 8001:443 -e ASPNETCORE_URLS="https://+;http://+" -e ASPNETCORE_HTTPS_PORT=8001 -e ASPNETCORE_Kestrel__Certificates__Default__Password="password" -e ASPNETCORE_Kestrel__Certificates__Default__Path=/https/aspnetapp.pfx -v $env:USERPROFILE\.aspnet\https:/https/ $ImageName
        if ($?)
        {
            echo "> Done"
            echo ""
            echo "> Navigating to '$WebSitePath'..."
            Start-Sleep -s 2
            Start-Process $WebSitePath #Opens the provided webpath in your default browser is all goes well
            if ($?)
            {            
                echo "> Done"
                echo ""
                echo "======================================="
                echo "script successfully finished executing!"
                echo "======================================="
                echo ""
                docker ps
            }
            else {
                echo "> ERROR: COULD NOT NAVIGATE TO '$WebSitePath', PLEASE ATTEMPT TO NAVIGATE TO THE WEBSITE MANAULLY"
                echo "================"
                echo "Script Finished."
                echo "================"
            }
        }
        else {
            echo "> ERROR: COULD NOT CREATE A CONTAINER FROM THE DOCKER IMAGE"
            echo "!!!!!!!!!!!!!!!"
            echo "Script aborting"
            echo "!!!!!!!!!!!!!!!"
        }
        
    }
    else {
        echo "> ERROR: COULD NOT SUCCESSFULLY BUILD THE APPLICATION, PLEASE BUILD IN VISUAL STUDIOS AND CHECK FOR BUILD ERRORS"
        echo "!!!!!!!!!!!!!!!"
        echo "Script aborting"
        echo "!!!!!!!!!!!!!!!"
    }
} 
else {
    echo "> ERROR: UNABLE TO FIND OR CHANGE TO THE DIRECTORY '$ProjectPath'"
    echo "!!!!!!!!!!!!!!!"
    echo "Script aborting"
    echo "!!!!!!!!!!!!!!!"
}