# apache-htaccess-config.yaml - Apache .htaccess for WordPress
# Generated from template for customer: {{ .Values.cluster.customerName }}

apiVersion: v1
kind: ConfigMap
metadata:
  name: apache-htaccess-config
  namespace: {{ .Values.cluster.customerName }}
data:
  .htaccess: |
    <IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteBase /
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_URI} !=/server-status 
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
    </IfModule>