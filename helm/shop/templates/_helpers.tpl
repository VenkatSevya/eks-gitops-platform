{{- define "shop.labels" -}}
app.kubernetes.io/part-of: shop
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/* Image for a service: <registry>/shop-<name>:<tag>, or shop-<name>:<tag> locally */}}
{{- define "shop.image" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- if $root.Values.image.registry -}}
{{ $root.Values.image.registry }}/shop-{{ $name }}:{{ $root.Values.image.tag }}
{{- else -}}
shop-{{ $name }}:{{ $root.Values.image.tag }}
{{- end -}}
{{- end }}

{{- define "shop.containerSecurity" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{- define "shop.dbEnv" -}}
- name: DB_HOST
  value: postgres
- name: DB_NAME
  value: {{ .Values.db.name | quote }}
- name: DB_USER
  value: {{ .Values.db.user | quote }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: shop-db
      key: password
{{- end }}
