#!/bin/bash
# Script to download upstream manifests and customize for ppc64le
# Author: Punith Kenchappa

set -e

KUBEVIRT_VERSION=${KUBEVIRT_VERSION:-v1.3.1}
REGISTRY=${REGISTRY:-quay.io/pkenchap}
VERSION=${VERSION:-v1.0.0-ppc64le}
OUTPUT_DIR=${OUTPUT_DIR:-_build/manifests}

echo "=========================================="
echo "KubeVirt Manifest Preparation for ppc64le"
echo "=========================================="
echo ""

# Create output directory
mkdir -p ${OUTPUT_DIR}

echo "1. Downloading upstream operator manifest..."
curl -L -s -o /tmp/kubevirt-operator-upstream.yaml \
  "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"

echo "2. Customizing operator manifest..."
# Replace operator image references with custom ppc64le images
sed -e "s|quay.io/kubevirt/virt-operator:[^ ]*|${REGISTRY}/virt-operator:${VERSION}|g" \
    -e "s|registry:5000/kubevirt/virt-operator:[^ ]*|${REGISTRY}/virt-operator:${VERSION}|g" \
    -e "s|value: quay.io/kubevirt/virt-operator:[^ ]*|value: ${REGISTRY}/virt-operator:${VERSION}|g" \
    /tmp/kubevirt-operator-upstream.yaml > /tmp/kubevirt-operator-temp.yaml

echo "3. Adding missing RBAC permissions..."
# Add missing subresources.kubevirt.io permissions to the operator ClusterRole
cat > /tmp/rbac-patch.yaml << 'EOF'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kubevirt-operator-subresources
  labels:
    kubevirt.io: ""
rules:
  - apiGroups:
      - subresources.kubevirt.io
    resources:
      - virtualmachineinstances/objectgraph
      - virtualmachines/objectgraph
      - virtualmachineinstances/usbredir
      - virtualmachineinstances/reset
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - policy
    resources:
      - poddisruptionbudgets
    verbs:
      - get
      - list
      - watch
      - create
      - delete
      - update
      - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubevirt-operator-subresources
  labels:
    kubevirt.io: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kubevirt-operator-subresources
subjects:
  - kind: ServiceAccount
    name: kubevirt-operator
    namespace: kubevirt
EOF

# Combine the operator manifest with the RBAC patch
cat /tmp/kubevirt-operator-temp.yaml /tmp/rbac-patch.yaml > ${OUTPUT_DIR}/kubevirt-operator.yaml

echo "4. Downloading upstream CR manifest..."
curl -L -s -o /tmp/kubevirt-cr-upstream.yaml \
  "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"

echo "5. Customizing CR manifest..."
# Add imageRegistry and imageTag to the CR
cat /tmp/kubevirt-cr-upstream.yaml | \
  sed '/^spec:/a\  imageRegistry: '${REGISTRY}'\n  imageTag: '${VERSION} \
  > ${OUTPUT_DIR}/kubevirt-cr.yaml

echo ""
echo "✓ Manifests prepared successfully!"
echo ""
echo "Configuration:"
echo "  Upstream Version: ${KUBEVIRT_VERSION}"
echo "  Custom Registry:  ${REGISTRY}"
echo "  Custom Version:   ${VERSION}"
echo "  Output Directory: ${OUTPUT_DIR}"
echo ""
echo "Generated files:"
echo "  - ${OUTPUT_DIR}/kubevirt-operator.yaml"
echo "  - ${OUTPUT_DIR}/kubevirt-cr.yaml"
echo ""
echo "To deploy KubeVirt:"
echo "  kubectl apply -f ${OUTPUT_DIR}/kubevirt-operator.yaml"
echo "  kubectl wait --for=condition=Ready pod -l kubevirt.io=virt-operator -n kubevirt --timeout=300s"
echo "  kubectl apply -f ${OUTPUT_DIR}/kubevirt-cr.yaml"
echo ""
echo "To monitor deployment:"
echo "  kubectl get pods -n kubevirt -w"
echo ""

# Made with Bob
