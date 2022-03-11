# Solar Edge

A Ruby app which sends data for a given SolarEdge installation to a MQTT message queue.
This app is build to integrate with [Balena Weather](https://github.com/hferentschik/balena-weather).

## Production

Each push to the GitHub repository will create a new container and upload it to the Docker Hub.
Pushes to branches receive the branch name as container tag.
Pushing a tag to GitHub builds the container with the specified tag.
A push to master creates a _latest_ container.
