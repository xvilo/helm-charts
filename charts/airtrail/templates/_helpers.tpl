{{- define "airtrail.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "airtrail.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "airtrail.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "airtrail.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "airtrail.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "airtrail.selectorLabels" -}}
app.kubernetes.io/name: {{ include "airtrail.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "airtrail.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{/*
Render a name->value map as container `env:` entries. Each value may be:
  - a scalar (string/number) -> rendered as `value: "..."`
  - a map                    -> rendered as-is (e.g. `valueFrom: { secretKeyRef: {...} }`)
Empty/nil scalar values are skipped. Expects the map as `.`.
*/}}
{{- define "airtrail.renderEnvMap" -}}
{{- range $name, $value := . }}
{{- if kindIs "map" $value }}
- name: {{ $name }}
{{ toYaml $value | indent 2 }}
{{- else if $value }}
- name: {{ $name }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Database env: individual components (string or secretKeyRef object) plus a
     DB_URL assembled from them at runtime via Kubernetes $(VAR) interpolation.
     DB_URL is listed last so every referenced var is declared before it. */}}
{{- define "airtrail.databaseEnv" -}}
{{- include "airtrail.renderEnvMap" (dict
  "DB_HOST" .Values.database.host
  "DB_PORT" .Values.database.port
  "DB_NAME" .Values.database.name
  "DB_USERNAME" .Values.database.username
  "DB_PASSWORD" .Values.database.password
) }}
- name: DB_URL
  value: "postgres://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)"
{{- end -}}
