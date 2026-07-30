# mysql-hostpath.yaml - MySQL StatefulSet with Secret
# Generated from template for customer: {{ .Values.cluster.customerName }}
# Deployed on node: {{ .Values.cluster.workerNode }}

{{- if .Values.database.secret.create }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Values.database.secret.name }}
  namespace: {{ .Values.cluster.customerName }}
type: Opaque
data:
  password: {{ .Values.database.secret.data.password | quote }}
  root-password: {{ .Values.database.secret.data.rootPassword | quote }}

---
{{- end }}
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: {{ .Values.cluster.customerName }}
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
      protocol: TCP

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: {{ .Values.cluster.customerName }}
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
      customer: {{ .Values.cluster.customerName }}
  template:
    metadata:
      labels:
        app: mysql
        customer: {{ .Values.cluster.customerName }}
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - {{ .Values.cluster.workerNode }}
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
          protocol: TCP
        readinessProbe:
          tcpSocket:
            port: mysql
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 6
        livenessProbe:
          tcpSocket:
            port: mysql
          initialDelaySeconds: 60
          periodSeconds: 20
          timeoutSeconds: 3
          failureThreshold: 6
        resources:
          limits:
            cpu: {{ .Values.resources.mysql.cpuLimits }}
            memory: {{ .Values.resources.mysql.memoryLimits }}
          requests:
            cpu: {{ .Values.resources.mysql.cpuRequests }}
            memory: {{ .Values.resources.mysql.memoryRequests }}
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.database.secret.name }}
              key: root-password
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.database.secret.name }}
              key: password
        - name: MYSQL_DATABASE
          value: "{{ .Values.database.service.name }}"
        - name: MYSQL_USER
          value: "{{ .Values.database.service.user }}"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-data
        hostPath:
          path: /mnt/k8s-storage/mysql-{{ .Values.cluster.customerName }}
          type: DirectoryOrCreate