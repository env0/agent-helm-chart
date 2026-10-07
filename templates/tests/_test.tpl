{{- define "env0-agent.test" -}}
apiVersion: v1
kind: Pod
metadata:
  name: &name "{{ include "env0-agent.releaseName" .root }}-{{ .testName }}-test"
  {{- with .labels }}
  labels:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  restartPolicy: Never
  {{- with .root.Values.additionalPodConfig }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{ if or ( .root.Values.agentImagePullSecret ) ( .root.Values.agentImagePullSecretRef ) }}
  imagePullSecrets:
    - name: {{ if .root.Values.agentImagePullSecret }}env0-image-pull-secret-{{ .root.Release.Name }}{{ else }}{{ .root.Values.agentImagePullSecretRef }}{{ end }}
  {{ end }}
  {{ if .persistentVolumeClaim }}
  volumes:
    - name: env0-state-volume
      persistentVolumeClaim:
        claimName: env0-state-volume-claim
  {{- end }}
  containers:
    - name: *name
      {{- with include "env0-agent.strict-security-context" .root }}{{ . | trim | nindent 6 }}{{ end }}
      image: {{ .root.Values.dockerImage }}
      imagePullPolicy: Always
      {{ if .persistentVolumeClaim -}}
      volumeMounts:
        - name: env0-state-volume
          mountPath: {{ include "env0-agent.stateMountPath" .root }}
        - name: env0-state-volume
          mountPath: "/mnt/shared"
      {{- end }}
      command:
        - /bin/bash
        - -ec
        - |
{{ include .commands .root | indent 10 }}
  {{- include "env0-agent.tolerations" (ternary .root.Values.tolerations .root.Values.deploymentTolerations (empty .root.Values.deploymentTolerations)) | nindent 2 }}
  {{- include "env0-agent.affinity" (ternary .root.Values.affinity .root.Values.deploymentAffinity (empty .root.Values.deploymentAffinity)) | nindent 2 }}
{{- end -}}
