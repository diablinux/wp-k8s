# apache-vhost-config.yaml - Apache Virtual Host Configuration
# Generated from template for customer: {{ .Values.cluster.customerName }}

apiVersion: v1
kind: ConfigMap
metadata:
  name: apache-vhost-config
  namespace: {{ .Values.cluster.customerName }}
data:
  000-default.conf: |
    <VirtualHost *:80>
    ServerAdmin {{ .Values.serverAdminEmail }}
    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <LocationMatch "^/server-status">
    SetHandler server-status
    Require local
    Require ip {{ join " " .Values.monitoring.allowedMetricsIPs }}
    </LocationMatch>

    <IfModule mod_proxy.c>
    ProxyStatus On
    </IfModule>
    </VirtualHost>