{{- define "stonker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "stonker.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "stonker.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "stonker.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "stonker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "stonker.backendImage" -}}
{{- printf "%s:%s" .Values.image.backend.repository (.Values.image.backend.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{- define "stonker.frontendImage" -}}
{{- printf "%s:%s" .Values.image.frontend.repository (.Values.image.frontend.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{- define "stonker.jwtSecretName" -}}
{{- if .Values.jwt.existingSecret -}}{{ .Values.jwt.existingSecret }}{{- else -}}{{ include "stonker.fullname" . }}-jwt{{- end -}}
{{- end -}}

{{/* Shared env: non-secret config + the app secret bundle. */}}
{{- define "stonker.envFrom" -}}
- configMapRef:
    name: {{ include "stonker.fullname" . }}-config
- secretRef:
    name: {{ include "stonker.fullname" . }}
{{- end -}}

{{/* JWT key files mounted at the path the app expects. */}}
{{- define "stonker.jwtVolume" -}}
- name: jwt-keys
  secret:
    secretName: {{ include "stonker.jwtSecretName" . }}
{{- end -}}
{{- define "stonker.jwtVolumeMount" -}}
- name: jwt-keys
  mountPath: /app/config/jwt
  readOnly: true
{{- end -}}

{{/*
Market-data env vars. Each value under .Values.marketData may be either:
  - a string  -> rendered as `value: "..."`
  - a map     -> rendered as-is (e.g. `valueFrom: { secretKeyRef: {...} }`)
Empty/nil values are skipped so the image's .env defaults apply.
*/}}
{{- define "stonker.marketDataEnv" -}}
{{- $vars := dict
  "EODHD_API_KEY" .Values.marketData.eodhdApiKey
  "TWELVEDATA_API_KEY" .Values.marketData.twelveDataApiKey
  "OPENFIGI_API_KEY" .Values.marketData.openFigiApiKey
  "YAHOO_USER_AGENT" .Values.marketData.yahooUserAgent
  "YAHOO_COOKIE" .Values.marketData.yahooCookie
-}}
{{- range $name, $value := $vars }}
{{- if $value }}
- name: {{ $name }}
{{- if kindIs "string" $value }}
  value: {{ $value | quote }}
{{- else }}
{{ toYaml $value | indent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/* Init container that blocks until the database accepts connections. */}}
{{- define "stonker.waitForDb" -}}
- name: wait-for-db
  image: {{ include "stonker.backendImage" . }}
  imagePullPolicy: {{ .Values.image.backend.pullPolicy }}
  command:
    - sh
    - -c
    - 'until php bin/console dbal:run-sql "SELECT 1" >/dev/null 2>&1; do echo "waiting for database…"; sleep 2; done'
  envFrom:
    {{- include "stonker.envFrom" . | nindent 4 }}
{{- end -}}
