{{- define "env0-agent.customCertificatesVolumes" -}}
{{- if .Values.customCertificates -}}
- name: etc-ssl-certs
  emptyDir: { }
- name: custom-certificates
  projected:
    sources:
      {{- range .Values.customCertificates }}
      - secret:
          name: {{ . }}
    {{- end -}}
{{- end -}}
{{- end -}}

{{- define "env0-agent.customCertificatesVolumesMounts" -}}
{{- if .Values.customCertificates -}}
- name: etc-ssl-certs
  mountPath: /etc/ssl/certs
- name: custom-certificates
  mountPath: /usr/local/share/ca-certificates
  readOnly: true
{{- end -}}
{{- end -}}

{{- define "env0-agent.customCertificatesNodeOptions" -}}
{{- if .Values.customCertificates -}}
- name: NODE_EXTRA_CA_CERTS
  value: /etc/ssl/certs/ca-certificates.crt
{{- end -}}
{{- end -}}
