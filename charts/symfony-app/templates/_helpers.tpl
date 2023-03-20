{{/*
Expand the name of the chart.
*/}}
{{- define "symfony-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "symfony-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "symfony-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "symfony-app.labels" -}}
helm.sh/chart: {{ include "symfony-app.chart" . }}
{{ include "symfony-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ (default .Chart.AppVersion .Values.source.version) | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "symfony-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "symfony-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "symfony-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "symfony-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the pod env variables
*/}}
{{- define "symfony-app.env" -}}
env:
{{- toYaml .Values.env | nindent 2 }}
  - name: GIT_SSH_COMMAND
    value: "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -vvvvv"
  {{- if .Values.pyroscope.config.server }}
  - name: PYROSCOPE_SERVER_ADDRESS
    value: "{{ .Values.pyroscope.config.server }}"
  {{ end }}
  {{- if .Values.pyroscope.enabled }}
  - name: PYROSCOPE_APPLICATION_NAME
    value: "{{- default (include "symfony-app.fullname" .) .Values.pyroscope.config.name }}"
  {{ end }}
{{- end }}