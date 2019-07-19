set -x

export GCE_INI_PATH=./gce.ini
gcloud compute addresses create entry-point --global --network-tier=PREMIUM --ip-version IPV4
EXTERNAL_IP=$(gcloud compute forwarding-rules describe entry-point --global | grep IPAddress: | awk -F ": " '{ print $2 }')
if [ -z $1 ]; then
  ansible-playbook -i inventory/gce.py\
   --tags=phase1\
   playbooks/cluster-up.yaml
  
  ansible-playbook -i inventory/gce.py\
   --tags=phase2\
   playbooks/cluster-up.yaml

  ./gcloud.sh

  EXTERNAL_IP=$(gcloud compute forwarding-rules describe entry-point --global | grep IPAddress: | awk -F ": " '{ print $2 }')

  ansible-playbook -i inventory/gce.py\
   --extra-vars "external_ip=${EXTERNAL_IP}"\
   --tags=phase3\
   playbooks/cluster-up.yaml
  
  ansible-playbook -i inventory/gce.py\
   --extra-vars "external_ip=${EXTERNAL_IP}"\
   --skip-tags "phase1,phase3,phase2,apps"\
   playbooks/cluster-up.yaml
  
  ansible-playbook -i inventory/gce.py\
   --extra-vars "external_ip=${EXTERNAL_IP}"\
   --tags="helm"\
   playbooks/cluster-up.yaml
  
  ansible-playbook -i inventory/gce.py\
   --extra-vars "external_ip=${EXTERNAL_IP}"\
   --tags="apps"\
   playbooks/cluster-up.yaml
else
  ansible-playbook -i inventory/gce.py\
   --extra-vars "external_ip=${EXTERNAL_IP}"\
   --tags=$1 playbooks/cluster-up.yaml
fi
echo "Services accessible using ${EXTERNAL_IP}."
set +x
