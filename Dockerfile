FROM codercom/code-server:latest

RUN sudo apt-get update && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - 

RUN sudo apt-get install -y --no-install-recommends python3 python3-pip default-jdk nodejs && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/*
