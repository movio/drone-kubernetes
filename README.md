# Kubernetes plugin for drone.io [Docker Repository on Docker Cloud](https://cloud.docker.com/app/razorpay/repository/docker/razorpay/drone-kubernetes)
## Borrowed and distilled from [honestbee/drone-kubernetes](https://github.com/honestbee/drone-kubernetes)

This plugin allows to update a Kubernetes deployment.
  - Cert based auth for tls
  - Insecure auth without tls

This version deprecates token based auth

## Usage

This pipeline will update the `my-deployment` deployment with the image tagged `DRONE_COMMIT_SHA:0:8`

```yaml
pipeline:
  deploy:
    image: razorpay/drone-kubernetes
    pull: true
    secrets:
      - docker_username
      - docker_password
      - server_url_<cluster>
      - server_cert_<cluster>
      - client_cert_<cluster>
      - client_key_<cluster>
      - ...
    user: <kubernetes-user with a cluster-rolebinding>
    cluster: <kubernetes-cluster>
    deployment: [<kubernetes-deployements, ...>]
    repo: <org/repo>
    container: [ <containers,...> ]
    namespace: <kubernetes-namespace>
    tag:
      - ${DRONE_REPO_BRANCH}-${DRONE_COMMIT_SHA}
      - ...
    when:
      environment: <kubernetes-cluster>
      branch: [ <branches>,... ]
      event:
        exclude: [push, pull_request, tag]
        include: [deployment]
```


## Required secrets

  - server_url
  - tls:
    - server_cert
      - `kubectl get secret [ your default secret name ] -o yaml | egrep 'ca.crt:' > ca.crt`
      - `kubectl get secret [ your default secret name ] -o yaml | egrep 'ca.key:' > ca.key`
    - client_cert
    - client_key
      - ```
        openssl genrsa -out client.key
        openssl req -new -key client.key -out client.csr -subj "/CN=drone/O=org"
        openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 500
        ```
      - ```
        cat ca.crt | base64 > car.crt.enc
        cat client.crt | base64 > client.crt.enc
        cat client.key | base64 > client.key.enc
        ```
      - ```
        drone secret add -repository razorpay/gimli -image razorpay/drone-kubernetes -event deployment -name server_url_<cluster> -value https://k8s.org.com.:443
        drone secret add -repository razorpay/gimli -image razorpay/drone-kubernetes -event deployment -name server_cert_<cluster> -value @./ca.crt.enc
        drone secret add -repository razorpay/gimli -image razorpay/drone-kubernetes -event deployment -name client_cert_<cluster> -value @./client.crt.enc
        drone secret add -repository razorpay/gimli -image razorpay/drone-kubernetes -event deployment -name client_key_<cluster> -value @./client.key.enc
        ```

When using TLS Verification, ensure Server Certificate used by kubernetes API server
is signed for SERVER url ( could be a reason for failures if using aliases of kubernetes cluster )

### RBAC

When using a version of kubernetes with RBAC (role-based access control)
enabled, you will not be able to use the default service account, since it does
not have access to update deployments.  Instead, you will need to create a
custom service account with the appropriate permissions (`Role` and `RoleBinding`, or `ClusterRole` and `ClusterRoleBinding` if you need access across namespaces using the same service account).

As an example (for the `web` namespace):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: drone-deploy
  namespace: web

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: drone-deploy
  namespace: web
rules:
  - apiGroups: ["extensions"]
    resources: ["deployments"]
    verbs: ["get","list","patch","update"]

---

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: drone-deploy
  namespace: web
subjects:
  - kind: ServiceAccount
    name: drone-deploy
    namespace: web
roleRef:
  kind: Role
  name: drone-deploy
  apiGroup: rbac.authorization.k8s.io
```

Once the service account is created, you can extract the `ca.cert` and `token`
parameters as mentioned for the default service account above:

```
kubectl -n web get secrets
# Substitute XXXXX below with the correct one from the above command
kubectl -n web get secret/drone-deploy-token-XXXXX -o yaml | egrep 'ca.crt:|token:'
```

## To do

Replace the current kubectl bash script with a go implementation.

### Special thanks

Inspired by [drone-helm](https://github.com/ipedrazas/drone-helm).
