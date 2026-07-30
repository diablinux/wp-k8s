# wordpress-hostpath.yaml - WordPress Deployment with Apache & Exporter
# Generated from template for customer: {{ .Values.cluster.customerName }}
# Deployed on node: {{ .Values.cluster.workerNode }}

apiVersion: v1
kind: Service
metadata:
  name: wordpress
  namespace: {{ .Values.cluster.customerName }}
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9117"
    prometheus.io/path: "/metrics"
spec:
  type: ClusterIP
  selector:
    app: wordpress
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
    - name: metrics
      port: 9117
      targetPort: 9117
      protocol: TCP
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: {{ .Values.cluster.customerName }}
spec:
  revisionHistoryLimit: 0
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9117"
        prometheus.io/path: "/metrics"
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
      - name: wordpress
        image: wordpress:{{ .Values.wordpress.version }}-apache
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
          name: http
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /wp-login.php
            port: http
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 6
        livenessProbe:
          httpGet:
            path: /wp-login.php
            port: http
          initialDelaySeconds: 60
          periodSeconds: 20
          timeoutSeconds: 5
          failureThreshold: 6
        resources:
          limits:
            cpu: {{ .Values.resources.wordpress.cpuLimits }}
            memory: {{ .Values.resources.wordpress.memoryLimits }}
          requests:
            cpu: {{ .Values.resources.wordpress.cpuRequests }}
            memory: {{ .Values.resources.wordpress.memoryRequests }}
        env:
        - name: WORDPRESS_AUTH_KEY
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.authKey }}
        - name: WORDPRESS_SECURE_AUTH_KEY
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.secureAuthKey }}
        - name: WORDPRESS_LOGGED_IN_KEY
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.loggedInKey }}
        - name: WORDPRESS_NONCE_KEY
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.nonceKey }}
        - name: WORDPRESS_AUTH_SALT
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.authSalt }}
        - name: WORDPRESS_SECURE_AUTH_SALT
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.secureAuthSalt }}
        - name: WORDPRESS_LOGGED_IN_SALT
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.loggedInSalt }}
        - name: WORDPRESS_NONCE_SALT
          valueFrom:
            secretKeyRef:
              name: {{ .Values.wordpress.secret.name }}
              key: {{ .Values.wordpress.secret.keys.nonceSalt }}
        - name: WORDPRESS_DB_HOST
          value: "mysql.{{ .Values.cluster.customerName }}.svc.cluster.local"
        - name: WORDPRESS_DB_USER
          value: "{{ .Values.database.service.user }}"
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.database.secret.name }}
              key: password
        - name: WORDPRESS_DB_NAME
          value: "{{ .Values.database.service.name }}"
        - name: WORDPRESS_CONFIG_EXTRA
          value: |
            define('WP_MEMORY_LIMIT', '256M');
            define('WP_MAX_MEMORY_LIMIT', '512M');
        
        volumeMounts:
        - name: wp-content
          mountPath: /var/www/html/wp-content
        - name: apache-vhost-config
          mountPath: /etc/apache2/sites-available/000-default.conf
          readOnly: false
          subPath: 000-default.conf
        - name: apache-htaccess-config
          mountPath: /var/www/html/.htaccess
          subPath: .htaccess
          readOnly: false
        
      # Apache Exporter sidecar for Prometheus metrics
      - name: apache-exporter
        image: bitnami/apache-exporter:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9117
          name: metrics
          protocol: TCP
        args:
          - --scrape_uri=http://localhost/server-status?auto
        resources:
          requests:
            memory: "32Mi"
            cpu: "10m"
          limits:
            memory: "64Mi"
            cpu: "50m"
      volumes:
      - name: wp-content
        hostPath:
          path: /mnt/k8s-storage/wordpress-{{ .Values.cluster.customerName }}
          type: DirectoryOrCreate
      
      - name: apache-vhost-config
        configMap:
          name: apache-vhost-config
          defaultMode: 0644
      
      - name: apache-htaccess-config
        configMap:
          name: apache-htaccess-config
          defaultMode: 0644
