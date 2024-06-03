{{- define "env0-agent.affinity" }}
    {{- if . -}}
        affinity: {{ . | toYaml | trim | nindent 2 }}
    {{- end -}}
{{- end -}}

{{- define "env0-agent.tolerations" -}}
    {{- if . -}}
        tolerations: {{ . | toYaml | trim | nindent 2 }}
    {{- end -}}
{{- end -}}
