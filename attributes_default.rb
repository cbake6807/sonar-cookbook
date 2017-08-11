default['bbt_sonarqube']['user'] = 'sonar'
default['bbt_sonarqube']['group'] = 'sonar'

default['bbt_sonarqube']['sonar_group_id'] = '180'
default['bbt_sonarqube']['sonar_user_uid'] = '20647'

# Installs JDK
default['bbt_sonarqube']['oracle_java_version'] = '1.8.0_101'
# Sonarqube Download
default['bbt_sonarqube']['sonarqube_file'] = ''
default['bbt_sonarqube']['remotefile_checksum'] = ''
default['bbt_sonarqube']['version'] = '5.6.6'
default['bbt_sonarqube']['os_kernel'] = 'linux-x86-64'

default['bbt_sonarqube']['config']['dir'] = '/opt/sonar/sonarqube-%{version}/conf'
default['bbt_sonarqube']['config']['file'] = 'sonar.properties'

default['bbt_sonarqube']['sonarqube_plugins_url'] = 'url'
default['bbt_sonarqube']['sonar_plugins'] = %w(
sonar-ldap-plugin-2.0.jar
sonar-javascript-plugin-2.21.1.4786.jar
sonar-java-plugin-4.11.0.10660.jar
sonar-cobol-plugin-3.4.0.1932.jar
sonar-checkstyle-plugin-2.4.jar
sonar-abap-plugin-3.3.jar
sonar-cfamily-plugin-4.10.0.8366.jar
sonar-clirr-plugin-1.3.jar
sonar-clover-plugin-3.1.jar
sonar-cobertura-plugin-1.7.jar
sonar-php-plugin-2.10.0.2087.jar
sonar-tab-metrics-plugin-1.4.1.jar
sonar-timeline-plugin-1.5.jar
sonar-widget-lab-plugin-1.8.1.jar
sonar-xml-plugin-1.4.3.1027.jar
sonar-findbugs-plugin.jar
sonar-ruby-plugin-1.0.1.jar
sonar-widget-lab-plugin-1.8.1.jar
)


# JDBC credentials
default['bbt_sonarqube']['jdbc_username'] = 'username'
default['bbt_sonarqube']['jdbc_password'] = 'secured'


# service start/stop
default['bbt_sonarqube']['services']['sonarqube'] = true

# JDBC URL
default['bbt_sonarqube']['postgres_jdbc'] = 'url'
default['bbt_sonarqube']['mssql_jdbc'] = 'server_name'

# Ldap Configuration
# General Configuration
default['bbt_sonarqube']['security_realm'] = 'LDAP'
default['bbt_sonarqube']['ldap_url'] = ''
default['bbt_sonarqube']['bindDn'] = ''
default['bbt_sonarqube']['password'] = 'Secret'

# User Configuration
default['bbt_sonarqube']['user-baseDn'] = ''
default['bbt_sonarqube']['user_req'] = ''
default['bbt_sonarqube']['realNmaeAttribute'] = 'cn'
default['bbt_sonarqube']['emailAttribute'] = 'mail'

# Group Configuration
default['bbt_sonarqube']['group_baseDn'] = 'DC=,DC='
default['bbt_sonarqube']['group_request'] = ')'

#SSL Certs path
default['bbt_sonarqube']['SSL_Chain'] = 'crt'
default['bbt_sonarqube']['Key_File'] =  '.pem'
default['bbt_sonarqube']['SSL_File'] = '.cer'


#Proxy passes
default['bbt_sonarqube']['ServerName'] = 'sonar-dev.bbtnet.com'
default['bbt_sonarqube']['Redirect_Permanent'] = 'https:/.com'
default['bbt_sonarqube']['ProxyPass'] =  'http:/9000/'
default['bbt_sonarqube']['PassReverse'] = 'https:/9000/'
