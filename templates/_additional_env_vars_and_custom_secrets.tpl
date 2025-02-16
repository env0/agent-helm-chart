{{- define "env0-agent.agent-additional-env-vars" -}}

{{- $additional_env_vars := list -}}

{{- range $key, $value := .Values.agentAdditionalEnvVars }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}

{{- /* define agent-additional-env-vars */ -}}
{{- end  -}}


{{- define "env0-agent.additional-env-vars-and-custom-secrets" -}}

{{- $additional_env_vars := list -}}
{{- $additional_secrets := list -}}

{{- range $key, $value := .Values.podAdditionalEnvVars -}}
    {{- $additional_env_vars = append $additional_env_vars (printf "\"%s\"" $key) -}}
{{- end -}}

{{- range $index, $secret := .Values.customSecrets -}}
    {{- $additional_env_vars = append $additional_env_vars (printf "\"%s\"" $secret.envVarName) -}}
    {{- $additional_secrets = append $additional_secrets (printf "\"%s\"" $secret.envVarName) -}}
{{- end -}}

{{- if $additional_env_vars }}
- name: ADDITIONAL_ENV_VARS
  value: '[{{ $additional_env_vars | join "," }}]'
{{- end -}}

{{- if $additional_secrets }}
- name: ADDITIONAL_SECRETS_NAMES
  value: '{{ $additional_secrets | join "," }}'
{{- end -}}

{{- range $key, $value := .Values.podAdditionalEnvVars }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}

{{- range $index, $secret := .Values.customSecrets }}
- name: {{ $secret.envVarName }}
  valueFrom:
    secretKeyRef:
      name: {{ $secret.secretName }}
      key: {{ $secret.key }}
{{- end -}}

{{- /* define additional-env-vars-and-custom-secrets */ -}}
{{- end -}}
