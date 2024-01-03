{% set kartaca_password = salt['pillar.get']('users:kartaca:kartaca_password') %}
{% set mysql_database = salt['pillar.get']('mysql:database') %}
{% set mysql_user = salt['pillar.get']('mysql:user') %}
{% set mysql_password = salt['pillar.get']('mysql:password') %}
{% set mysql_root_password = salt['pillar.get']('mysql:root_password') %}

kartaca_group_membership:
  group.present:
    - name: kartaca
    - gid: 2023

kartaca_users:
  user.present:
    - name: kartaca
    - uid: 2023
    - gid: 2023
    - home: /home/krt
    - shell: /bin/bash
    - require:
      - group: kartaca

kartaca_password:
  cmd.run:
    - name: echo 'kartaca:{{ kartaca_password }}' | sudo chpasswd
    - shell: /bin/bash
    - require:
      - user: kartaca

# Kartaca Kullanıcısının Sudo Yetkileri
kartaca_sudo_privileges:
  file.managed:
    - name: /etc/sudoers.d/kartaca
    - contents: |
        kartaca ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/yum
        kartaca ALL=(ALL) ALL
    - mode: 440
    - require:
      - user: kartaca
      - cmd: kartaca_password

# Zaman Dilimi Ayarı
Europe/Istanbul:
  timezone.system:
    - utc: True

# IP Forwarding Ayarı
ip_forwarding:
  sysctl.present:
    - name: net.ipv4.ip_forward
    - value: 1
    - config: /etc/sysctl.conf

apply_sysctl:
  cmd.run:
    - name: sysctl -p
    - require:
      - sysctl: ip_forwarding

# Gerekli Paketlerin Kurulumu
{% if grains['os_family'] == 'Debian' %}
install_htop:
  pkg.installed:
    - name: htop

install_tcptraceroute:
  pkg.installed:
    - name: tcptraceroute

install_ping:
  pkg.installed:
    - name: iputils-ping

install_dig:
  pkg.installed:
    - name: dnsutils

install_iostat:
  pkg.installed:
    - name: sysstat

install_mtr:
  pkg.installed:
    - name: mtr-tiny
{% elif grains['os_family'] == 'RedHat' %}

# EPEL Deposu Kontrolü ve Kurulumu
install_epel:
  pkg.installed:
    - name: epel-release

# htop Kurulumu
install_htop:
  pkg.installed:
    - name: htop
    - refresh: True

install_tcptraceroute:
  pkg.installed:
    - name: traceroute

install_ping:
  pkg.installed:
    - name: iputils

install_dig:
  pkg.installed:
    - name: bind-utils  # RedHat/CentOS için dig paket adı

install_iostat:
  pkg.installed:
    - name: sysstat

install_mtr:
  pkg.installed:
    - name: mtr  # RedHat/CentOS için MTR paket adı
{% endif %}

# HashiCorp Deposu Kurulumu
{% if grains['os_family'] == 'Debian' %}
install_hashicorp_repo:
  cmd.run:
    - name: |
        sudo apt update && sudo apt install gpg
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update
{% elif grains['os_family'] == 'RedHat' %}
install_hashicorp_repo:
  cmd.run:
    - name: |
        wget -O- https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
        sudo yum makecache
{% endif %}

# IP Adres Blokları ve Host Ekleme
{% set ip_block = '192.168.168.128/28' %}
{% set subnets = salt['cmd.run']('python3 -c "import ipaddress; print(list(ipaddress.IPv4Network(\'{}\')))"'.format(ip_block), python_shell=True) %}

{% for host_num in range(1, 16) %}
add_host_{{ host_num }}:
  cmd.run:
    - name: |
        if ! grep -q "{{ subnets.split(',')[host_num] }} kartaca.local" /etc/hosts; then
          echo "{{ subnets.split(',')[host_num] }} kartaca.local" | sudo tee -a /etc/hosts
        fi
{% endfor %}

#----------------

{% if grains['os_family'] == 'RedHat' %}
# Nginx Kurulumu
nginx:
  pkg.installed:
    - name: nginx

# Nginx Servisi
nginx_service:
  service.running:
    - name: nginx
    - enable: True

# PHP Modülleri
php_modules:
  pkg.installed:
    - names:
      - php
      - php-fpm
      - php-mysqlnd
      - php-cli

# WordPress İndirme
wordpress_download:
  cmd.run:
    - name: "cd /tmp && wget -O wordpress.tar.gz https://wordpress.org/latest.tar.gz"
    - creates: /tmp/wordpress.tar.gz

# WordPress Çıkartma
wordpress_extraction:
  cmd.run:
    - name: >
        cd /var/www &&
        mkdir -p wordpress2023 &&
        tar xzf /tmp/wordpress.tar.gz -C wordpress2023 --strip-components=1 &&
        semanage fcontext -a -t httpd_sys_content_t "/var/www/wordpress2023(/.*)?" &&
        restorecon -R /var/www/wordpress2023
    - creates: /var/www/wordpress2023
    - require:
      - cmd: wordpress_download

# Nginx Yapılandırma Dosyasının Güncellenmesi
reload_nginx_on_config_update:
  cmd.run:
    - name: "systemctl reload nginx"
    - unless: "test `stat -c %Y /etc/nginx/nginx.conf` -le `stat -c %Y /var/cache/salt/minion/files/base/etc/nginx/nginx.conf`"

# wp-config.php Dosyasının Güncellenmesi
update_wp_config:
  cmd.run:
    - name: |
        sed -i "s/database_name_here/{{ salt['pillar.get']('mysql:database', 'default_database') }}/g; s/username_here/{{ salt['pillar.get']('mysql:user', 'default_user') }}/g; s/password_here/{{ salt['pillar.get']('mysql:password', 'default_password') }}/g" /var/www/wordpress2023/wp-config-sample.php
    - require:
      - cmd: wordpress_extraction

# wp-config-sample.php Dosyasının wp-config.php'ye Kopyalanması
copy_wp_config:
  cmd.run:
    - name: cp /var/www/wordpress2023/wp-config-sample.php /var/www/wordpress2023/wp-config.php
    - require:
      - cmd: update_wp_config

# WordPress İçin Secret Key'lerin Güncellenmesi
update_wordpress_keys:
  cmd.run:
    - name: |
        curl -sS https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/wordpress2023/wp-config.php
    - require:
      - cmd: copy_wp_config

# Nginx Yapılandırmasının Salt ile Yönetilmesi
manage_nginx_configuration:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: nginx
    - watch_in:
      - cmd: reload_nginx_on_config_update

# Nginx'in Ayın İlk Gününde Yeniden Başlatılacak Cron'un Oluşturulması
restart_nginx_monthly:
  cmd.run:
    - name: "echo '0 0 1 * * systemctl restart nginx' >> /etc/crontab"
    - require:
      - pkg: nginx

# Nginx Loglarının Saatlik Rotate Edilmesi
nginx_hourly_log_rotate:
  cmd.run:
    - name: "/usr/sbin/logrotate -f /etc/logrotate.d/nginx"
{% endif %}

#----------------

{% if grains['os_family'] == 'Debian' %}
# MySQL Veritabanı Kurulumu
mysql_server:
  pkg.installed:
    - name: mysql-server

# MySQL Servisi
mysql_service:
  service.running:
    - name: mysql
    - enable: True

# MySQL Kullanıcısı ve Veritabanı Oluşturma
create_mysql_user:
  cmd.run:
    - name: |
        mysql -uroot{{ ' -p' + mysql_root_password if mysql_root_password }} -e "CREATE USER '{{ mysql_user }}'@'localhost' IDENTIFIED BY '{{ mysql_password }}';"
        mysql -uroot{{ ' -p' + mysql_root_password if mysql_root_password }} -e "CREATE DATABASE IF NOT EXISTS {{ mysql_database }};"
    - require:
      - pkg: mysql_server
    - output_loglevel: 'debug'

# MySQL Kullanıcısına Yetkileri Verme
grant_mysql_privileges:
  cmd.run:
    - name: |
        mysql -uroot{{ ' -p' + mysql_root_password if mysql_root_password }} -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE ON *.* TO '{{ mysql_user }}'@'localhost';"
        mysql -uroot{{ ' -p' + mysql_root_password if mysql_root_password }} -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE ON {{ mysql_database }}.* TO '{{ mysql_user }}'@'localhost';"
    - require:
      - cmd: create_mysql_user
    - output_loglevel: 'debug'

# MySQL Database Dump'ının Her Gece 02:00'de Alınacak Cron'unun Oluşturulması
mysql_backup_cron:
  cron.present:
    - name: /usr/bin/mysqldump -u{{ mysql_user }} -p{{ mysql_password }} {{ mysql_database }} > /backup/mysql_backup.sql
    - identifier: mysql_backup
    - user: root
    - minute: 0
    - hour: 2
{% endif %}
