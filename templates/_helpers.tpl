{{- define "env0-agent.stateMountPath" -}}
{{- ternary "/mnt/public/" "/mnt/private/env0" (.Values.strictSecurityContext | default false) -}}
{{- end -}}

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

{{- define "env0-agent.isSelfHosted" -}}
{{- if hasKey .Values "isSelfHosted" -}}
  {{- .Values.isSelfHosted | toString -}}
{{- else -}}
  {{- "true" -}}
{{- end -}}
{{- end -}}

{{- define "env0-agent.stage" -}}
{{- .Values.stage | default "prod" -}}
{{- end -}}

{{- define "env0-agent.releaseName" -}}
{{- .Release.Name | replace "." "-" -}}
{{- end -}}

{{- define "env0-agent.version-env-vars" -}}
- name: IMAGE_TAG
  value: {{ .Values.dockerImage | quote }}
- name: RELEASE_VERSION
  value: {{ trimPrefix "v" .Chart.AppVersion | quote }}
{{- end -}}

{{- define "env0-agent.shouldUsePVC" -}}
{{- $secretValue := dict -}}

{{- if (hasKey .Values "env0ConfigSecretName") -}}
  {{- $secretValue = (lookup "v1" "Secret" .Release.Namespace .Values.env0ConfigSecretName).data -}}
{{- end -}}

{{- if (hasKey .Values "env0StateEncryptionKey") -}}
  false
{{- else if eq (include "env0-agent.isSelfHosted" .) "false" -}}
  false
{{- else if (not (hasKey .Values "env0ConfigSecretName")) -}}
{{- /* no env0StateEncryptionKey or isSelfHosted in Values AND no env0ConfigSecretName provided */ -}}
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
