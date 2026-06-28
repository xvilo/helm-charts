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

{{/* Secret holding the DB connection URL — either the user's existingSecret
     or the one this chart generates from database.url / components. */}}
{{- define "airtrail.secretName" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecret -}}
{{- else -}}
{{- include "airtrail.fullname" . -}}
{{- end -}}
{{- end -}}

{{- define "airtrail.dbUrlKey" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecretKey | default "db-url" -}}
{{- else -}}
db-url
{{- end -}}
{{- end -}}
