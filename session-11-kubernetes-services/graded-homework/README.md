# Lecture 11 Graded Homework

### Task 1: Kubernetes Port Architecture & Clarification Drill

- **Short Description:** Document and visually map the 4 distinct port definitions in Kubernetes. Illustrate how a packet flows from an external client through the node, into the service, and down to the application process inside the container.
- **Manifest Reference:** Concept mapping across all `service.yaml` and `app-deployment.yaml` files.
- **Key Commands:**
    
    ```bash
    # Inspect port declarations across pod and service
    kubectl explain pod.spec.containers.ports.containerPort
    kubectl explain service.spec.ports
    ```
    
- **Architecture Flowchart:**
    
    ```
    Client Browser ──► [nodePort: 30080] (Host IP)
                            │
                            ▼
                       [port: 8080] (Service VIP)
                            │
                            ▼
                       [targetPort: 80] (Pod Network)
                            │
                            ▼
                       [containerPort: 80] (Container Engine / Nginx)
    ```

---

### Task 2: Type 1 Service — ClusterIP (Default Internal Networking)

- **Short Description:** Deploy a 3-replica backend (`web-app-clusterip`), create a `ClusterIP` service on port `8080` targeting container port `80`, inspect automatic endpoint binding, and test connectivity from an ephemeral client pod using short names and full FQDN.
- **Working Directory:** `session-11-kubernetes-services/`
- **Commands to Run:**
    
    ```bash
    # 1. Deploy backend app and ClusterIP service
    kubectl apply -f 01-clusterip/app-deployment.yaml
    kubectl apply -f 01-clusterip/service.yaml
    
    # 2. Verify pods, service, and endpoints
    kubectl get pods -l app=web-clusterip -o wide
    kubectl get svc web-service-clusterip
    kubectl get endpoints web-service-clusterip
    
    # 3. Deploy diagnostic client pod
    kubectl apply -f 01-clusterip/client-pod.yaml
    kubectl wait --for=condition=ready pod/curl-client --timeout=60s
    
    # 4. Test internal resolution methods from inside the cluster
    kubectl exec -it curl-client -- curl -s <http://web-service-clusterip:8080> | grep -i "<title>"
    kubectl exec -it curl-client -- curl -s <http://web-service-clusterip.default.svc.cluster.local:8080> | grep -i "<title>"
    ```
    
- **📸 Screenshots:**
    > ![alt text](screenshots/image.png)

---

### Task 3: Type 2 Service — NodePort (Host-Level External Ingress)

- **Short Description:** Deploy a 2-replica Nginx app and expose it externally by opening port `30080` on every cluster node. Verify that hitting any node IP on port `30080` directs traffic to the underlying pods.
- **Working Directory:** `session-11-kubernetes-services/`
- **Commands to Run:**
    
    ```bash
    # 1. Deploy application and NodePort service
    kubectl apply -f 02-nodeport/app-deployment.yaml
    kubectl apply -f 02-nodeport/service.yaml
    
    # 2. Verify the NodePort mapping
    kubectl get svc web-service-nodeport
    
    # 3. Retrieve Minikube IP and verify node port access
    MINIKUBE_IP=$(minikube ip)
    curl -I <http://$>{MINIKUBE_IP}:30080
    
    # 4. Alternatively test via minikube service tunnel (macOS/Docker driver)
    minikube service web-service-nodeport --url
    ```
    
- **📸 Screenshots:**
    > ![alt text](screenshots/image-1.png)

---

### Task 4: Type 3 Service — LoadBalancer (Cloud-Native Ingress Simulation)

- **Short Description:** Deploy a 3-replica workload exposed through `type: LoadBalancer`. Use `minikube tunnel` to simulate a cloud provider assigning an `EXTERNAL-IP`, and confirm that Kubernetes automatically configures internal `NodePort` and `ClusterIP` layers.
- **Working Directory:** `session-11-kubernetes-services/`
- **Commands to Run:**
    
    ```bash
    # 1. Deploy application and LoadBalancer service
    kubectl apply -f 03-loadbalancer/app-deployment.yaml
    kubectl apply -f 03-loadbalancer/service.yaml
    
    # 2. Check service status (will initially show <pending> without tunnel)
    kubectl get svc web-service-loadbalancer
    
    # 3. In a separate terminal, start the Minikube LoadBalancer tunnel
    minikube tunnel
    
    # 4. In primary terminal, observe EXTERNAL-IP populated
    kubectl get svc web-service-loadbalancer
    
    # 5. Access the application directly on standard port 80
    EXTERNAL_IP=$(kubectl get svc web-service-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    curl -s <http://$>{EXTERNAL_IP}:80 | grep -i "<title>"
    ```
    
- **📸 Screenshots:**
    > ![alt text](screenshots/image-2.png)
    > ![alt text](screenshots/image-3.png)
---

### Task 5: Type 4 Service — ExternalName (CoreDNS CNAME Alias Redirection)

- **Short Description:** Create an `ExternalName` service that acts as an internal DNS CNAME alias pointing to an external domain (e.g., `api.github.com`). Verify that no cluster IP or endpoints are created, and confirm CNAME resolution using `nslookup`.
- **Working Directory:** `session-11-kubernetes-services/`
- **Commands to Run:**
    
    ```bash
    # 1. Apply ExternalName service and client pod
    kubectl apply -f 04-externalname/service.yaml
    kubectl apply -f 04-externalname/client-pod.yaml
    kubectl wait --for=condition=ready pod/dns-test-client --timeout=60s
    
    # 2. Inspect the service (Notice CLUSTER-IP is <none>, EXTERNAL-IP is the target domain)
    kubectl get svc external-database-service
    
    # 3. Verify DNS resolution returns canonical name (CNAME)
    kubectl exec -it dns-test-client -- nslookup external-database-service
    
    # 4. Test outbound traffic through the alias
    kubectl exec -it dns-test-client -- curl -s -k <https://external-database-service>
    ```
    
- **📸 Screenshots:**
    > ![alt text](screenshots/image-4.png)
    > ![alt text](screenshots/image-5.png)

---

### Task 6: Type 5 Service — Headless Service (`clusterIP: None` & Stateful Workloads)

- **Short Description:** Deploy a 3-replica `StatefulSet` with a Headless Service (`clusterIP: None`). Prove that CoreDNS returns individual `A` records for all matching Pod IPs directly rather than a single VIP, and curl an ordinal pod hostname directly.
- **Working Directory:** `session-11-kubernetes-services/`
- **Commands to Run:**
    
    ```bash
    # 1. Apply Headless service and StatefulSet
    kubectl apply -f 05-headless/service.yaml
    kubectl apply -f 05-headless/app-statefulset.yaml
    kubectl apply -f 05-headless/client-pod.yaml
    
    # 2. Wait for stateful pods (web-stateful-0, 1, 2) to become Ready
    kubectl rollout status statefulset/web-stateful --timeout=120s
    kubectl get pods -l app=web-headless -o wide
    
    # 3. Inspect Service (Notice CLUSTER-IP is explicitly None)
    kubectl get svc web-service-headless
    
    # 4. Perform DNS lookup on Headless Service name -> Returns ALL pod IPs
    kubectl exec -it headless-dns-client -- nslookup web-service-headless
    
    # 5. Query an individual Pod directly via its stable FQDN
    kubectl exec -it headless-dns-client -- nslookup web-stateful-0.web-service-headless.default.svc.cluster.local
    kubectl exec -it headless-dns-client -- curl -s <http://web-stateful-0.web-service-headless:80> | grep -i "<title>"
    ```
    
- **📸 Screenshots:**
    > ![alt text](screenshots/image-6.png)

---

Here is the rewritten assignment task matching your exact directory structure and file names so you can paste it directly into your documentation or README.

### Task 7: Services Without Selectors (Manual Endpoints Mapping)

* **Short Description:** Define a Service without selectors and manually bind it to an external backend IP address using a separate Endpoints manifest. Demonstrate how Kubernetes abstracts legacy or external infrastructure.
* **Working Directory:** `session-11-kubernetes-services/`
* **Files Used:** `06-without-selector/service.yaml` and `06-without-selector/endpoints.yaml`
* **Commands to Run:**
```bash
# 1. Apply the Service without a selector
kubectl apply -f 06-without-selector/service.yaml

# 2. Verify endpoints are initially empty (<none>)
kubectl get endpoints external-legacy-db

# 3. Manually create matching Endpoints object pointing to external IP
kubectl apply -f 06-without-selector/endpoints.yaml

# 4. Verify endpoints are now successfully attached
kubectl get endpoints external-legacy-db

```


* **📸 Screenshots:**
    > ![alt text](screenshots/image-7.png)

---

### Task 8: FQDN & CoreDNS Deep Dive Architecture Analysis

* **Short Description:** Inspect the cluster DNS configuration inside running pods. Break down the anatomy of a Kubernetes FQDN, examine `/etc/resolv.conf`, test search domain completion, and explain why `ndots:5` causes latency in production when making external API calls.
* **Working Directory:** `session-11-kubernetes-services/`
* **Commands to Run:**
```bash
# 1. Verify CoreDNS pods are active in kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide

# 2. Create the missing client pod & sample target service
kubectl run curl-client --image=busybox:1.36 --restart=Never -- sleep 3600
kubectl wait --for=condition=ready pod/curl-client --timeout=60s
kubectl create service clusterip web-service-clusterip --tcp=80:80

# 3. Inspect /etc/resolv.conf inside running pod
kubectl exec -it curl-client -- cat /etc/resolv.conf

# 4. Test DNS search domain expansion (Short name & Full FQDN)
kubectl exec -it curl-client -- nslookup web-service-clusterip
kubectl exec -it curl-client -- nslookup web-service-clusterip.default.svc.cluster.local

# 5. Demonstrate ndots:5 external query traversal
kubectl exec -it curl-client -- nslookup api.github.com

```


* **📸 Screenshots:**
    > ![alt text](screenshots/image-8.png)
    >![alt text](screenshots/image-9.png)

---

### Task 9: Pod Identity & Lifecycle Invariance Drill — Deployment (Stateless) vs. StatefulSet (Stateful)

- **Short Description:** Deploy both a stateless Deployment and an ordinal StatefulSet. Inspect their naming schemes, delete a running pod from each controller using `kubectl delete pod`, and observe that the Deployment spawns an ephemeral pod with a completely new random hash, whereas the StatefulSet strictly resurrects the exact same ordinal index (`web-stateful-0`).
- **Manifest Reference:**
    - Deployment: `session-11-kubernetes-services/01-clusterip/app-deployment.yaml`
    - StatefulSet: `session-11-kubernetes-services/05-headless/app-statefulset.yaml`
    - Service: `session-11-kubernetes-services/05-headless/service.yaml`
- **Commands to Run:**
    
    ```bash
    # 1. Apply both workloads
    kubectl apply -f session-11-kubernetes-services/01-clusterip/app-deployment.yaml
    kubectl apply -f session-11-kubernetes-services/05-headless/service.yaml
    kubectl apply -f session-11-kubernetes-services/05-headless/app-statefulset.yaml
    
    # 2. Wait for pods to become Ready and observe the naming conventions
    kubectl get pods -l app=web-clusterip
    kubectl get pods -l app=web-headless
    
    # 3. Capture the exact pod names before deletion
    DEPLOY_POD=$(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[0].metadata.name}')
    echo "Deleting Stateless Deployment Pod: ${DEPLOY_POD}"
    kubectl delete pod "${DEPLOY_POD}"
    
    # 4. Check the Deployment pods immediately — notice a brand-new random hash is generated!
    kubectl get pods -l app=web-clusterip
    
    # 5. Delete an ordinal StatefulSet pod (web-stateful-0)
    echo "Deleting StatefulSet Pod: web-stateful-0"
    kubectl delete pod web-stateful-0
    
    # 6. Check the StatefulSet pods immediately — notice web-stateful-0 is recreated identically!
    kubectl get pods -l app=web-headless
    ```
    
- **📸 Screenshots:**
    > ![alt text](screenshots/image-10.png)
    > ![alt text](screenshots/image-11.png)

---

### Task 10: Production Cost Optimization & Service Selection Decision Tree

- **Short Description:** Document the Kubernetes Service Decision Tree and conduct a cost-optimization analysis. Detail why provisioning 50 `type: LoadBalancer` services creates an enterprise billing anti-pattern in public clouds (AWS/GCP/Azure) and demonstrate how an Ingress Controller eliminates this overhead.
- **Architecture Diagram:**
    
    ```
    ANTI-PATTERN (Expensive: $25/mo per service):
    Microservice A ──► AWS NLB 1 ($25/mo) ──► ClusterIP A
    Microservice B ──► AWS NLB 2 ($25/mo) ──► ClusterIP B
    Microservice C ──► AWS NLB 3 ($25/mo) ──► ClusterIP C
    Total for 50 services = $1,250 / month
    
    BEST PRACTICE (Cost-Optimized: Single Entrypoint):
    Public Internet ──► 1 Unified AWS Load Balancer ($25/mo)
                                │
                                ▼
                     [ NGINX Ingress Controller ]
                     (Layer 7 Host & Path Routing)
                        │            │            │
                        ▼            ▼            ▼
                   ClusterIP A  ClusterIP B  ClusterIP C
    Total for 50 services = $25 / month (Savings: $1,225/mo)
    ```
    
- **Service Selection Logic Tree:**
    
    ```
    Need to expose service outside cluster?
    │
    ├── NO ──► Need direct pod-to-pod discovery (Kafka/DB)?
    │           ├── YES ──► Use HEADLESS SERVICE (clusterIP: None)
    │           └── NO  ──► Use CLUSTERIP (Default)
    │
    └── YES ──► Connecting to an external 3rd-party domain (AWS RDS / Stripe)?
                ├── YES ──► Use EXTERNALNAME
                └── NO  ──► Are you on Public Cloud (AWS/GCP/Azure)?
                             ├── YES (HTTP/HTTPS) ──► Expose 1 INGRESS via LOADBALANCER,
                             │                        apps as internal CLUSTERIP
                             ├── YES (TCP/UDP)    ──► Direct LOADBALANCER
                             └── NO (On-Prem/Dev) ──► NODEPORT
    ```

---

### Task 11: Minikube Docker-Driver Port Binding & Tunnel Gotcha Analysis

- **Short Description:** Analyze and document why running `curl http://<Node-IP>:<NodePort>` fails on macOS and Windows when using Minikube with the Docker driver. Execute and verify the two standard operational solutions: the temporary network forwarder (`minikube service <svc> --url`) and the continuous Layer 3 routing daemon (`minikube tunnel`).
- **Root Cause Explanation:**
    - In standard bare-metal Linux clusters, the worker node IP belongs directly to a physical interface reachable on the local network.
    - When using Minikube on macOS or Windows with the Docker driver (`-driver=docker`), Minikube runs inside an **isolated Docker container**. The node IP (e.g., `192.168.49.2`) belongs to an internal Docker network bridge (`docker0`/`bridge`) that macOS/Windows host kernels cannot directly route to without specialized proxying.