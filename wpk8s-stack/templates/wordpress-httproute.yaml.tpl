apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: wordpress-route-{{ .Values.cluster.customerName }}
  namespace: {{ .Values.cluster.customerName }}
spec:
  hostnames:
  - {{ .Values.network.domain }}
  parentRefs:
  - name: {{ .Values.network.ingress.gatewayName }}
    namespace: {{ .Values.network.ingress.namespace }}
    sectionName: {{ .Values.network.ingress.sectionName }}
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - group: ""
      kind: Service
      name: wordpress
      port: 80
      weight: 1
  - matches:
    - path:
        type: PathPrefix
        value: /metrics
    backendRefs:
    - group: ""
      kind: Service
      name: wordpress
      port: 9117
      weight: 1
