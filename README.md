# lazerbahn.com

Repository for website at lazerbahn.com.
This is the prototype for a simple flat file CMS driven by a static page generator.

It's completely build on Docker. For simplicity, all Docker interactivity is encapsulated in shell scripts:

    ./up.sh         # build container and start it 
    ./down.sh       # stop container and delete it
    ./shell.sh      # open shell into container
    ./build.sh      # build the html files

Build a new version of static pages run

    ./build.sh

To expose the docker container on a custom port other than 80, copy `.env.dist` to `.env` and change the
`LOCAL_PORT` variable.