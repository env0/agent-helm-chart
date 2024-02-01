{{- define "env0-agent.test" -}}
apiVersion: v1
kind: Pod
metadata:
  name: &name "{{ .root.Release.Name }}-{{ .testName }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  {{ if .root.Values.agentImagePullSecret }}
  imagePullSecrets: {{ toYaml .root.Values.agentImagePullSecret | nindent 4 }}
  {{ end }}
  {{ if .persistentVolumeClaim }}
  volumes:
    - name: env0-state-volume
      persistentVolumeClaim:
        claimName: env0-state-volume-claim
  {{- end }}
  containers:
    - name: *name
      image: {{ .root.Values.dockerImage }}
      imagePullPolicy: Always
      {{ if .persistentVolumeClaim -}}
      volumeMounts:
        - name: env0-state-volume
          mountPath: {{ .root.Values.stateMountPath }}
      {{- end }}
      {{ if .env -}}
      env:
{{ include .env .root | indent 8 }}
      {{- end }}
      command:
        - /bin/bash
        - -ec
        - |
{{ include .commands .root | indent 10 }}

{{ if .tolerationsAndAffinity }}
  {{ if .root.Values.tolerations }}
  # Warning - every whitespace here matters
  tolerations: {{ range $i, $toleration := .root.Values.tolerations }}
    -
    {{ range $k, $v := $toleration }}  {{ $k }}: {{ $v }}
    {{ end }}{{ end }}
  {{ end }}
  {{ if .root.Values.affinity }}
  affinity: {{ .root.Values.affinity | toYaml | trim | nindent 10 }}
  {{ end }}
{{- end -}}
{{- end -}}
