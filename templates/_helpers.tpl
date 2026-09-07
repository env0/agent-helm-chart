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

{{- /* Omitted when the isSelfHosted value is unset: agent code treats an absent IS_SELF_HOSTED_K8S as self-hosted (ATH-457) */ -}}
{{- define "env0-agent.isSelfHostedEnvVar" -}}
{{- if hasKey .Values "isSelfHosted" -}}
- name: IS_SELF_HOSTED_K8S
  value: {{ include "env0-agent.isSelfHosted" . | quote }}
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

{{- /* Kubernetes base64-decodes a Secret's data:, and the decoded bytes reach the container as env
       vars, which the runtime rejects unless they are valid UTF-8. Hence base64 of text. */ -}}
{{- define "env0-agent.assertBase64" -}}
{{- $decoded := .value | b64dec -}}
{{- /* Kubernetes ignores \r and \n in a data: value and no other whitespace, so line-wrapped
       base64 - what base64(1) emits without -w0 - has to compare equal here too */ -}}
{{- $canonical := .value | replace "\r" "" | replace "\n" "" -}}
{{- $encode := "Encode it with: printf '%s' '<value>' | base64 -w0" -}}
{{- if ne ($decoded | b64enc) $canonical -}}
{{- fail (printf "%s must be base64-encoded, because the chart writes it into a Kubernetes Secret's data: field, which Kubernetes base64-decodes. %s" .name $encode) -}}
{{- /* %q writes \xNN for exactly the bytes that are not valid UTF-8, so it accepts any real text
       including non-ASCII. Escaped backslashes go first, or a literal \xNN in the text would match. */ -}}
{{- else if regexMatch "\\\\x[0-9a-fA-F]{2}" (printf "%q" $decoded | replace "\\\\" "") -}}
{{- fail (printf "%s must be base64 of valid UTF-8 text: the decoded bytes reach the agent as an environment variable, and the container runtime rejects one that is not. If the value you were given is itself a generated key such as a base64 or hex string, encode that string rather than the bytes behind it. %s" .name $encode) -}}
{{- end -}}
{{- end -}}

{{- /* agentAccessToken is absent: the chart b64enc's that one itself */ -}}
{{- define "env0-agent.validateEncodedSecretValues" -}}
{{- $values := .Values -}}
{{- range $name := list
  "agentImagePullSecret"
  "assumerKeyIdEncoded"
  "assumerSecretEncoded"
  "bitbucketServerCredentialsEncoded"
  "customerAwsAccessKeyIdEncoded"
  "customerAwsSecretAccessKeyEncoded"
  "customerAzureClientId"
  "customerAzureClientSecret"
  "customerAzureTenantId"
  "customerGoogleCredentials"
  "customerGoogleProject"
  "customerVaultTokenEncoded"
  "env0ApiGwKeyEncoded"
  "env0StateEncryptionKey"
  "environmentOutputEncryptionKey"
  "githubEnterpriseAppPrivateKeyEncoded"
  "gitlabEnterpriseCredentialsEncoded"
  "infracostApiKeyEncoded"
-}}
  {{- with (index $values $name) -}}
    {{- include "env0-agent.assertBase64" (dict "name" $name "value" .) -}}
  {{- end -}}
{{- end -}}
{{- range $name := list "tenancyOCIDEncoded" "userOCIDEncoded" "apiKeyFingerprintEncoded" "apiKeyPrivateKeyEncoded" "secretsRegion" -}}
  {{- with (index ($values.customerOracleCredentials | default dict) $name) -}}
    {{- include "env0-agent.assertBase64" (dict "name" (printf "customerOracleCredentials.%s" $name) "value" .) -}}
  {{- end -}}
{{- end -}}
{{- range $name := list "encodedToken" "encodedPassword" -}}
  {{- with (index ($values.vault | default dict) $name) -}}
    {{- include "env0-agent.assertBase64" (dict "name" (printf "vault.%s" $name) "value" .) -}}
  {{- end -}}
{{- end -}}
{{- end -}}
