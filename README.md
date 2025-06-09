1. Create NFS storage (In aws EFS).
2. Create VM name master and install docker in the vm then make it as docker swarm master using `docker swarm init` command (Note the token command) also mount the nfs storage.
3. Create Launch template and update the userdata with efs mount command and docker swarm token.
4. Clone the `https://github.com/taasheeadmin/docker-controller-deployment.git` repo with branch docker_swarm_with_db and update environment variables then use command `docker stack deploy -f docker-compose.yml code_server`.
5.Access the application in 80 port.
6.In swagger add scheduling time for auto scale down.
