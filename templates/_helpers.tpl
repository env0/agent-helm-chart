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
  runAsUser: 1000 # run as non-root "node" user
{{- end }}
{{- end }}
