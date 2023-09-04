# Utilize the following template variables.
## docker_fess_version
## node_name
## discovery_seed_hosts
## network_publish_host
## cluster_initial_master_nodes

env_file="/opt/setup-fess.env"
sudo echo "${docker_fess_version}" > $env_file
sudo echo "${node_name}" >> $env_file
sudo echo "${discovery_seed_hosts}" >> $env_file
sudo echo "${network_publish_host}" >> $env_file
sudo echo "${cluster_initial_master_nodes}" >> $env_file


# Setup Data Disk
device_name=$(ls -l /dev/disk/azure/scsi1/lun0 | grep -o 'sd[a-z]*')
sudo parted "/dev/$device_name" --script mklabel gpt mkpart xfspart xfs 0% 100%
sudo mkfs.xfs "/dev/${device_name}1"
sudo mkdir -p /mnt_datadisk
sudo mount "/dev/${device_name}1" /mnt_datadisk

# Install Docker
echo "Install docker"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce git

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Setup
echo "Setup vm.max_map_count"
sudo echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install Docker Fess
echo "Run Fess"
cd /opt || exit 1
sudo git clone -b ${docker_fess_version} https://github.com/codelibs/docker-fess.git
cd /opt/docker-fess/compose || exit 1

# Setup ES
sudo mkdir /mnt_datadisk/esdata01
sudo mkdir /mnt_datadisk/esdictionary01
sudo chown -R 1000:1000 /mnt_datadisk/esdata01
sudo chown -R 1000:1000 /mnt_datadisk/esdictionary01

es_compose_file="/opt/docker-fess/compose/compose-opensearch2.yaml"
cp -f "$es_compose_file" "${es_compose_file}.origin"
sed -i "s/- node.name=es01/- node.name=${node_name}/g" $es_compose_file
sed -i "s/- discovery.seed_hosts=es01/- discovery.seed_hosts=${discovery_seed_hosts}/g" $es_compose_file
sed -i "s/- cluster.initial_master_nodes=es01/- cluster.initial_master_nodes=${cluster_initial_master_nodes}/g" $es_compose_file
sed -i "s/- cluster.initial_cluster_manager_nodes=es01/- cluster.initial_cluster_manager_nodes=${cluster_initial_master_nodes}/g" $es_compose_file

sed -i 's@esdata01:/usr/share/elasticsearch/data@/mnt_datadisk/esdata01:/usr/share/elasticsearch/data@g' $es_compose_file
sed -i 's@esdictionary01:/usr/share/elasticsearch/config/dictionary@/mnt_datadisk/esdictionary01:/usr/share/elasticsearch/config/dictionary@g' "$es_compose_file"

sed -i "/environment:/a \      - network.publish_host=${network_publish_host}" $es_compose_file
sed -i "/ports:/a \      - 9300:9300" $es_compose_file

# Run Fess
docker compose --env-file .env -f compose.yaml -f compose-opensearch2.yaml up -d
# docker compose --env-file .env.elasticsearch -f compose.yaml -f compose-elasticsearch8.yaml up -d

