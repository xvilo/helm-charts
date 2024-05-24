# iSponsorBlockTV Helm Chart

This repository contains a Helm chart for iSponsorBlockTV.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm repo add xvilo https://xvilo.github.io/helm-charts
helm install my-release xvilo/isponsorblocktv
```

This command deploys iSponsorBlockTV on the Kubernetes cluster with the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm delete my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the iSponsorBlockTV chart and their default values.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `config.devices` | List of devices to be configured | `[]` |
| `config.apikey` | API key for iSponsorBlockTV | `""` |
| `config.skip_categories` | Categories to be skipped | `["sponsor", "selfpromo", "intro", "outro", "music_offtopic", "interaction", "exclusive_access", "poi_highlight", "preview", "filler"]` |
| `config.channel_whitelist` | List of channels to be whitelisted | `[]` |
| `config.skip_count_tracking` | Enable/Disable skip count tracking | `true` |
| `config.mute_ads` | Enable/Disable ad muting | `true` |
| `config.skip_ads` | Enable/Disable ad skipping | `true` |

You can specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm install my-release xvilo/isponsorblocktv --set config.apikey=yourapikey
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm install my-release -f values.yaml xvilo/isponsorblocktv
```

> **Tip**: You can use the default [values.yaml](values.yaml)

For more information on configuring your iSponsorBlockTV deployment, refer to the [values.yaml](values.yaml) file in this repository.