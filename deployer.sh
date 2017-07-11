set -xe

# ${WORKSPACE}: openshift-ansible-deployment/ 1, 2 ... deployer.sh  inventory.ini README.md

#
# Run:
# ./deployer.sh
#


BUILD_DIR="${WORKSPACE}/${BUILD_ID}"
INVENTORY_FILE="${WORKSPACE}/inventory.ini"
COPY_ID="${WORKSPACE}/copy-id.sh"
MY_INVENTORY_FILE="${BUILD_DIR}/inventory.ini"
OPENSHIFT_ANSIBLE_PATH="${BUILD_DIR}/openshift-ansible"
ID_FILE="${WORKSPACE}/../id_rsa"
WORKSPACE_ID_FILE="${WORKSPACE}/id_rsa"
export ANSIBLE_HOST_KEY_CHECKING=False

ansible --version
env

# Create build dir
mkdir ${BUILD_DIR}
echo "running in: ${BUILD_DIR}"

(cd ${BUILD_DIR} && git clone https://github.com/openshift/openshift-ansible $OPENSHIFT_ANSIBLE_PATH)

(cd $OPENSHIFT_ANSIBLE_PATH && exec git checkout -B deployment $OPENSHIFT_ANSIBLE_REF)

cp ${ID_FILE} ${WORKSPACE_ID_FILE}

# TODO: THERE HAS TO BE A BETTER WAY TO DO THIS

cp ${INVENTORY_FILE} ${MY_INVENTORY_FILE}

echo "openshift_master_default_subdomain=${MASTER_IP}.nip.io" >> ${MY_INVENTORY_FILE}
echo "oreg_url=openshift/origin-\${component}:${IMAGES_VERSION}" >> ${MY_INVENTORY_FILE}
echo "[masters]" >> ${MY_INVENTORY_FILE}
echo "origin-master.${MASTER_IP}.nip.io openshift_hostname=origin-master.${MASTER_IP}.nip.io" >> ${MY_INVENTORY_FILE}
echo "[nodes]" >> ${MY_INVENTORY_FILE}
echo "origin-master.${MASTER_IP}.nip.io openshift_hostname=origin-master.${MASTER_IP}.nip.io" >> ${MY_INVENTORY_FILE}
for ip in $INFRA_IPS
do
    echo "origin-infra01.${ip}.nip.io openshift_hostname=origin-infra01.${ip}.nip.io openshift_node_labels=\"{'region': 'infra', 'zone': 'default'}\"" >> ${MY_INVENTORY_FILE}
done
for ip in $COMPUTE_IPS
do
    echo "origin-compute01.${ip}.nip.io openshift_hostname=origin-compute01.${ip}.nip.io openshift_node_labels=\"{'region': 'primary', 'zone': 'default'}\" " >> ${MY_INVENTORY_FILE}
done
cat ${MY_INVENTORY_FILE}

if [ -n "${ROOT_PASSWORD}" ]; then
    sudo su - -c "source ${COPY_ID} ${ROOT_PASSWORD} ${MASTER_IP} ${INFRA_IPS} ${COMPUTE_IPS}"
fi

ansible-playbook  -vv \
                  --connection=ssh \
                  --become \
                  --become-user=root \
                  --private-key=${WORKSPACE_ID_FILE} \
                  --inventory=${MY_INVENTORY_FILE} \
                  -e "openshift_hosted_logging_master_public_url=https://${MASTER_IP}.nip.io:8443" \
                  -e "openshift_hosted_logging_ops_hostname=logging.${MASTER_IP}.nip.io" \
                  -e "openshift_hosted_logging_hostname=ops.logging.${MASTER_IP}.nip.io" \
                  -e "host_key_checking=False" \
                  ${OPENSHIFT_ANSIBLE_PATH}/playbooks/byo/config.yml \
