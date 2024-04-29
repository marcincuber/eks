MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${CLUSTER_NAME}
    apiServerEndpoint: ${API_SERVER_URL}
    certificateAuthority: ${B64_CLUSTER_CA}
    cidr: ${CLUSTER_SERVICE_CIDR}

--BOUNDARY--