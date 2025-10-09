# Intel GPU Exporter Helm Chart

![Version](https://img.shields.io/badge/helm--chart-intel--gpu--exporter-blue?style=flat-square)
![Kubernetes](https://img.shields.io/badge/kubernetes-v1.21%2B-blue?style=flat-square)

This Helm chart deploys the [Intel GPU Exporter](https://github.com/AndrewGolikov55/intel-gpu-exporter) onto a Kubernetes cluster.  
It exposes GPU metrics to Prometheus using [Node Feature Discovery (NFD)](https://github.com/kubernetes-sigs/node-feature-discovery) and the [Intel GPU Device Plugin](https://github.com/intel/intel-device-plugins-for-kubernetes).

---

## 📋 Prerequisites

Before installing this chart, ensure the following components are **installed and running** in your cluster:

1. [Node Feature Discovery (NFD)](https://github.com/kubernetes-sigs/node-feature-discovery)
2. [Intel Device Plugin Operator](https://github.com/intel/intel-device-plugins-for-kubernetes/tree/main/cmd/operator)
3. [Intel GPU Device Plugin](https://github.com/intel/intel-device-plugins-for-kubernetes/tree/main/cmd/gpu_plugin)

> 💡 These components label nodes with Intel GPU capabilities and expose GPU devices to containers.

---

## 🚀 Installation

First, add the Helm repository:

```bash
helm repo add xvilo https://xvilo.github.io/helm-charts
helm repo update
```

Then install the chart:
```
helm install intel-gpu-exporter xvilo/intel-gpu-exporter -n observability
```

To customize configuration, create a values.yaml and pass it to the install command:
```
helm install intel-gpu-exporter xvilo/intel-gpu-exporter -f values.yaml -n observability
```

### 📊 Metrics

Once deployed, the Intel GPU Exporter exposes GPU metrics at:

```
http://<pod-ip>:9100/metrics
```

You can configure Prometheus to scrape these endpoints automatically if it’s set up to discover pods with the appropriate annotations.


### 🧩 Example Prometheus Scrape Configuration

If your Prometheus doesn’t use Kubernetes service discovery, you can manually add a job:
```yaml
scrape_configs:
  - job_name: "intel-gpu-exporter"
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - observability
    relabel_configs:
      # Only scrape pods with label app=intel-gpu-exporter
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: intel-gpu-exporter
      # Use pod IP and port 9100
      - source_labels: [__meta_kubernetes_pod_ip]
        target_label: __address__
        regex: (.+)
        replacement: $1:9100
      # Optional: add node name as label
      - source_labels: [__meta_kubernetes_pod_node_name]
        target_label: kubernetes_node
```
