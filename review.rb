sq_version = node['bbt_sonarqube']['version']
sq_os_kernel = node['bbt_sonarqube']['os_kernel']

sq_user = node['bbt_sonarqube']['user']
sq_group = node['bbt_sonarqube']['group']

sq_config_dir = node['bbt_sonarqube']['config']['dir'] % { version: sq_version }
sq_zip_location = ::File.join(Chef::Config[:file_cache_path], "sonarqube-#{sq_version}.zip")
sq_runscript = "/opt/sonar/sonarqube-#{sq_version}/bin/#{sq_os_kernel}/sonar.sh"

include_recipe 'bbt_oracle_java'

oracle_java 'system_jre' do
  version node['bbt_sonarqube']['oracle_java_version']
  jdk true
  default_alternative true
  system_cacerts true
  unlimited_strength_jce true
end

# creates group
group sq_group do
  system true
  # TODO Will need gid set to ops assigned value.
end

# creates user
user sq_user do
  gid sq_group
  # TODO Will need uid set to ops assigned value.
  system true
end

# FIXME This may not be idempotent. Consider triggering this with a :before notification if the install directory does not exist.
remote_file 'Download remote file' do
  path sq_zip_location
  source node['bbt_sonarqube']['sonarqube_file']
  mode '0644'
  # enter md5 checksum here
  #checksum "123456789123456789"
  # TODO Enable useetag and use conditional get should be true.
  action :create_if_missing # download only if missing
end

package 'unzip'

# ensure directory exists before unzipping
directory sq_config_dir do
  recursive true
  mode '0744'
  owner sq_user
  group sq_group
  # TODO Add a before notification to trigger zip file download and unzip.
end

# FIXME This is not idempotent, causing unzips every time chef client runs.
# Perhaps trigger this after the remote_file download using a notification.
bash 'unzip installation' do
  code <<-EOF
    if [ ! -d "/opt/sonar/sonarqube-#{sq_version}" ]; then
      unzip #{sq_zip_location} -d /opt/sonar/
      chown -R #{sq_user}:#{sq_group} /opt/sonar/sonarqube-#{sq_version}
    fi
  EOF
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
  # TODO: We prefer that all the attributes used in the template are defined here.
  user: sq_user
  )
end


ldap_secret = node['bbt_sonarqube']['password']
jdbc_password = node['bbt_sonarqube']['jdbc_password']
if node['bbt_sonarqube']['sonar_credentials_databag'] && node['bbt_sonarqube']['sonar_credentials_databag_item']
  secrets = data_bag_item(node['bbt_sonarqube']['sonar_credentials_databag'], node['bbt_sonarqube']['sonar_credentials_databag_item'])
  ldap_secret = secrets['ldap_bind_pwd']
  jdbc_password = secrets['sonar_jdbc_password']
end


template 'update_sonar_properties' do
  source 'sonar.properties.erb'
  path '/opt/sonar/sonarqube-5.6.6/conf/sonar.properties'
  mode   '0644'
  owner sq_user
  group sq_group
  variables(
  # TODO: We prefer that all the attributes used in the template are defined here.
    user: sq_user,
    ldap_secret: ldap_secret,
    jdbc_password: jdbc_password
  )
end

node['bbt_sonarqube']['sonar_plugins'].each do |pkg|
  remote_file "/opt/sonar/sonarqube-5.6.6/extensions/plugins/#{pkg}" do
    source "https://artifactory.bbtnet.com/artifactory/jenkins-tools/#{pkg}"
    owner sq_user
    group sq_group
    action :create_if_missing # download only if missing
    # TODO: Add a mode that prevents other users from writing or executing this file.
  end
end

firewalld_interface 'em1' do
    action :add
    zone   'public'
    port_number 9000
    port_protocol 'tcp'
    firewall_action 'accept'
end

service 'sonarqube' do
  supports restart: true, reload: false, status: true
  action node['bbt_sonarqube']['services']['sonarqube'] ? [:enable, :start] : [:disable, :stop]
end
