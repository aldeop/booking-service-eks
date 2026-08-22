{{/*
Chart name, used for the standard app.kubernetes.io/name label.
*/}}
{{- define "booking-service.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{/*
Common labels applied to every resource this chart creates.
*/}}
{{- define "booking-service.labels" -}}
app.kubernetes.io/name: {{ include "booking-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels -- kept separate from the full label set because selectors
are immutable on a Deployment once created, so this set must never grow
extra labels (like a chart version) that would change between upgrades.
*/}}
{{- define "booking-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "booking-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
