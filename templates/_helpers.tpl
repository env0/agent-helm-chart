{{- define "env0-agent.http-proxy" -}}
{{ if .Values.httpProxy }}
- name: HTTP_PROXY
  value: {{ .Values.httpProxy | quote | default "~" }}
- name: http_proxy
  value: {{ .Values.httpProxy | quote | default "~" }}
{{ end }}
{{ if .Values.httpsProxy }}
- name: HTTPS_PROXY
  value: {{ .Values.httpsProxy | quote | default "~" }}
- name: https_proxy
  value: {{ .Values.httpsProxy | quote | default "~" }}
{{ end }}
{{ if .Values.noProxy }}
- name: NO_PROXY
  value: {{ .Values.noProxy | quote | default  "~" }}
- name: no_proxy
  value: {{ .Values.noProxy | quote | default  "~" }}
{{ end }}
{{- end -}}

{{- define "env0-agent.strict-security-context" }}
{{- if .Values.strictSecurityContext }}
securityContext:
  allowPrivilegeEscalation: false
  seccompProfile:
      type: RuntimeDefault
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: {{ .Values.runAsUser | default 1000 | int }}
  runAsGroup: {{ .Values.runAsGroup | default 1000 | int }}
{{- end }}
{{- end }}

{{- define "env0-agent.shouldUsePVC" -}}
{{- $secretValue := dict -}}
{{- if (hasKey .Values "env0ConfigSecretName") -}}
  {{- $secretValue = (lookup "v1" "Secret" .Release.Namespace .Values.env0ConfigSecretName).data -}}
{{- end -}}

{{- if (hasKey .Values "env0StateEncryptionKey") -}}
  false
{{- else if (not (hasKey .Values "env0ConfigSecretName")) -}}
{{- /* no env0StateEncryptionKey in Values AND no env0ConfigSecretName provided */ -}}
  true
{{- else -}}
  {{- if (hasKey $secretValue "ENV0_STATE_ENCRYPTION_KEY") -}}
  {{- /* k8s Secret contains ENV0_STATE_ENCRYPTION_KEY - no need for PVC */ -}}
    false
  {{- else -}}
  {{- /* k8s Secret does NOT contain ENV0_STATE_ENCRYPTION_KEY */ -}}
    true
  {{- end -}}
{{- end -}}
{{- end -}}
