{{- define "terraform-mcp.name" -}}
terraform-mcp
{{- end -}}

{{- define "terraform-mcp.fullname" -}}
{{ include "terraform-mcp.name" . }}
{{- end -}}
