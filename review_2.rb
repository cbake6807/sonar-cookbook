sq_version = node['bbt_sonarqube']['version']
sq_os_kernel = node['bbt_sonarqube']['os_kernel']

sq_user = node['bbt_sonarqube']['user']
sq_group = node['bbt_sonarqube']['group']

sq_config_dir = node['bbt_sonarqube']['config']['dir'] % { version: sq_version }
sq_zip_location = ::File.join(Chef::Config[:file_cache_path], "sonarqube-#{sq_version}.zip")
sq_runscript = "/opt/sonar/sonarqube-#{sq_version}/bin/#{sq_os_kernel}/sonar.sh"

include_recipe 'bbt_oracle_java'
include_recipe 'firewalld'


package 'unzip'
package 'httpd'
package 'mod_ssl'

# Install Oracle java
oracle_java 'system_jre' do
  version node['bbt_sonarqube']['oracle_java_version']
  jdk true
  default_alternative true
  system_cacerts true
  unlimited_strength_jce true
end


# creates group
group sq_group do
  gid node['bbt_sonarqube']['sonar_group_id']
  system true
end

# creates user
user sq_user do
  uid node['bbt_sonarqube']['sonar_user_uid']
  gid sq_group
  system true
end

# Downloads sonarqube
remote_file 'Download_Remote_File' do
  path sq_zip_location
  source node['bbt_sonarqube']['sonarqube_file']
  mode '0644'
  checksum node['bbt_sonarqube']['remotefile_checksum']
  use_etag true
  use_conditional_get true
  notifies :run, 'bash[Unzip_Installation]', :immediately
end

# unzip sonarqube zip file
bash 'Unzip_Installation' do
  code <<-EOF
    unzip #{sq_zip_location} -d /opt/sonar/
    chown -R #{sq_user}:#{sq_group} /opt/sonar/sonarqube-#{sq_version}
EOF
    action :nothing
end

# creates directory
directory sq_config_dir do
  recursive true
  mode '0744'
  owner sq_user
  group sq_group
  not_if { Dir.exists?(sq_config_dir) }
  notifies :create, 'remote_file[Download_Remote_File]', :before
end


# softlink for managing sonarqube
link '/usr/bin/sonarqube' do
  to sq_runscript
end

# template '/etc/init.d/sonarqube' do
template 'sonarqube_init.d' do
  source 'sonarqube.erb'
  path '/etc/init.d/sonarqube'
  mode   '0744'
  owner sq_user
  group sq_group
  variables(
  user: sq_user
  )
end

if File.exist?('/etc/chef/encrypted_data_bag_secret')
secret = Chef::EncryptedDataBagItem.load_secret("/etc/chef/encrypted_data_bag_secret")
item = Chef::EncryptedDataBagItem.load('role_sonarqube', 'sonar_credentials', secret)

item['certs'].each do |cert|
file "/etc/httpd/conf.d/#{cert['filename']}" do
  content cert['data']
  owner 'root'
#  verify { secret != false } # dont execute template block if databag is missing encrypted_data_bag_secret
  not_if { File.exist?("/etc/httpd/conf.d/#{cert['filename']}") }
  notifies :create, 'template[httpd.conf]', :immediately
  end
 end
end


# Default to node attributes
jdbc_username = node['bbt_sonarqube']['jdbc_username']
jdbc_password = node['bbt_sonarqube']['jdbc_password']
jdbc_url = node['bbt_sonarqube']['mssql_jdbc']
ldap_secret = node['bbt_sonarqube']['password']
server_name = node['bbt_sonarqube']['ServerName']
redirect_permanent = node['bbt_sonarqube']['Redirect_Permanent']
ssl_chainfile_path = node['bbt_sonarqube']['SSL_Chain']
ssl_key_file_path = node['bbt_sonarqube']['Key_File']
ssl_cert_file = node['bbt_sonarqube']['SSL_File']
proxypass = node['bbt_sonarqube']['ProxyPass']
proxypass_reverse = node['bbt_sonarqube']['PassReverse']


#if data bags
if node['bbt_sonarqube']['sonar_credentials_databag'] && node['bbt_sonarqube']['sonar_credentials_databag_item']
  secrets = data_bag_item(node['bbt_sonarqube']['sonar_credentials_databag'], node['bbt_sonarqube']['sonar_credentials_databag_item'])
  jdbc_username = secrets['jdbc_username']
  jdbc_password = secrets['sonar_jdbc_password']
  jdbc_url = secrets['jdbc_url']
  ldap_secret = secrets['ldap_bind_pwd']
  server_name = secrets['server_name']
  redirect_permanent = secrets['redirect_permanent']
  ssl_chainfile_path = secrets['ssl_chainfile_path']
  ssl_key_file_path = secrets['ssl_key_file_path']
  ssl_cert_file = secrets['ssl_cert_file']
  proxypass = secrets['proxypass']
  proxypass_reverse = secrets['proxypass_reverse']
end

template 'httpd.conf' do
  source 'httpd.conf.erb'
  path '/etc/httpd/conf/httpd.conf'
  owner 'root'
  group 'root'
  sensitive true
  variables(
    server_name: server_name,
    redirect_permanent: redirect_permanent,
    ssl_chainfile_path: ssl_chainfile_path,
    ssl_key_file_path: ssl_key_file_path,
    ssl_cert_file: ssl_cert_file,
    proxypass: proxypass,
    proxypass_reverse: proxypass_reverse
  )
  action :create
  #notifies :reload, 'service[httpd]', :delayed
  #verify { secret != false } # dont execute template block if databag is missing
end

# sonar.properties template
template 'update_sonar_properties' do
  source 'sonar.properties.erb'
  path '/opt/sonar/sonarqube-5.6.6/conf/sonar.properties'
  mode   '0644'
  owner sq_user
  group sq_group
  variables(
    jdbc_username: jdbc_username ,
    jdbc_password: jdbc_password ,
    jdbc_url: jdbc_url,
    ldap_secret: ldap_secret,
    realm: node['bbt_sonarqube']['security_realm'],
    ldap_url: node['bbt_sonarqube']['ldap_url'],
    bindDn: node['bbt_sonarqube']['bindDn'],
    baseDn: node['bbt_sonarqube']['user-baseDn'],
    user_req: node['bbt_sonarqube']['user_req'],
    realNmaeAttribute: node['bbt_sonarqube']['realNmaeAttribute'],
    user_emailAttribute: node['bbt_sonarqube']['emailAttribute'],
    group_baseDn: node['bbt_sonarqube']['group_baseDn'],
    group_req: node['bbt_sonarqube']['group_request']
  )
end

node['bbt_sonarqube']['sonar_plugins'].each do |pkg|
  remote_file "/opt/sonar/sonarqube-5.6.6/extensions/plugins/#{pkg}" do
    source "https://artifactory.bbtnet.com/artifactory/jenkins-tools/#{pkg}"
    action :create
    owner sq_user
    group sq_group
    mode '0644'
  end
end

# Opens firewall ports
firewalld_port '9000/tcp' do
  action :add
  zone 'public'
end

firewalld_port '80/tcp' do
  action :add
  zone 'public'
end

# restart apache if conf file changed
service 'httpd' do
   subscribes :reload, 'file[/etc/httpd/conf/httpd.conf]', :immediately
end

# starts sonarqube service
service 'sonarqube' do
  supports restart: true, reload: false, status: true
  action node['bbt_sonarqube']['services']['sonarqube'] ? [:enable, :start] : [:disable, :stop]
end
