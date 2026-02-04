#!/bin/bash

# ✅ Variables
USER_NAME="dev-user"
NAMESPACE="dev"
GROUP_NAME="dev-group"
CSR_NAME="${USER_NAME}"
CLUSTER_NAME=$(kubectl config current-context)

# ✅ Step 1: Generate Key and CSR
openssl genrsa -out ${USER_NAME}.key 2048
openssl req -new -key ${USER_NAME}.key -out ${USER_NAME}.csr -subj "/CN=${USER_NAME}/O=${GROUP_NAME}"

# ✅ Step 2: Encode CSR
CSR_BASE64=$(cat ${USER_NAME}.csr | base64 | tr -d '\n')

# ✅ Step 3: Create Kubernetes CSR
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  request: ${CSR_BASE64}
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
EOF

# ✅ Step 4: Approve CSR
kubectl certificate approve ${CSR_NAME}

# ✅ Step 5: Retrieve signed certificate
kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}' | base64 --decode > ${USER_NAME}.crt

# ✅ Step 6: Set user credentials in kubeconfig
kubectl config set-credentials ${USER_NAME} \
  --client-certificate=${USER_NAME}.crt \
  --client-key=${USER_NAME}.key

# ✅ Step 7: Create namespace (if not exists)
kubectl get namespace ${NAMESPACE} >/dev/null 2>&1 || kubectl create namespace ${NAMESPACE}

# ✅ Step 8: Set context for the new user
kubectl config set-context ${USER_NAME}-context \
  --cluster=${CLUSTER_NAME} \
  --namespace=${NAMESPACE} \
  --user=${USER_NAME}

# ✅ Step 9: Create Role and RoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ${NAMESPACE}
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER_NAME}-binding
  namespace: ${NAMESPACE}
subjects:
- kind: User
  name: ${USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# ✅ Step 10: Test access (optional)
echo -e "\n🔍 Try testing access using:"
echo "kubectl --context=${USER_NAME}-context get pods"


Run the script and then run few commands

--> kubectl config current-context // soumya.k8s.local
--> kubectl run nginx --image=nginx -n dev
--> kubectl --context=dev-user-context get pods //will work
--> kubectl --context=dev-user-context delete pod nginx //will not work

If you want to delete everything in one shot --> 

kubectl delete rolebinding dev-user-binding -n dev
kubectl delete role pod-reader -n dev
kubectl delete csr dev-user
kubectl config delete-context dev-user-context
kubectl config delete-user dev-user
rm -f dev-user.key dev-user.crt dev-user.csr
