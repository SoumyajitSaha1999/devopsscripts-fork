sudo dnf install ansible -y
sudo dnf install python3 python3-pip -y
ansible --version

# amazon-linux-extras install ansible2 -y
# yum install python3 python-pip python-dlevel -y



**********************************
# Deploy Nginx Config using Jinja2
**********************************
mkdir templates
cd templates

# 📌 Create a Jinja2 Template (templates/nginx.conf.j2)
vi nginx.conf.j2
server {
    listen {{ nginx_port }};
    server_name {{ server_name }};

    location / {
         root {{ web_root }};
        index index.html;
    }
}   

# **This template uses variables ({{ variable_name }}) that will be replaced dynamically.

Create a playbook (nginx.yml) to deploy the template:
cd ..
vi nginx.yml

---
- name: Deploy Nginx Config using Jinja2
  hosts: all
  become: yes
  vars:
    nginx_port: 80
    server_name: mywebsite.com
    web_root: /var/www/html

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

    - name: Copy Nginx Config with Template
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart NGINX

   handlers:
     - name: Restart NGINX
       service:
         name: nginx
         state: restarted
         
ansible-playbook nginx.yml

**********************************
Configure Apache HTTPD with Jinja2
**********************************
mkdir templates
cd templates

# 📌 Create a Jinja2 Template (templates/vi httpd.conf.j2)
vi httpd.conf.j2
Listen {{ http_port }}

<VirtualHost *:{{ http_port }}>
    ServerName {{ server_name }}
    DocumentRoot {{ document_root }}

    <Directory "{{ document_root }}">
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/{{ server_name }}_error.log
    CustomLog /var/log/httpd/{{ server_name }}_access.log combined
</VirtualHost>

Create a playbook (apache_setup.yml) to deploy the template:
cd ..
apache_setup.yml

---
- name: Configure Apache HTTPD with Jinja2
  hosts: all
  become: yes
  vars:
    http_port: 80
    server_name: example.com
    document_root: /var/www/html

  tasks:
    - name: Install Apache (httpd)
      yum:
        name: httpd
        state: present

    - name: Deploy Apache Configuration
      template:
        src: templates/httpd.conf.j2
        dest: /etc/httpd/conf/httpd.conf
      notify: Restart HTTPD

  handlers:
    - name: Restart HTTPD
      service:
        name: httpd
        state: restarted
        
ansible-playbook apache_setup.yml
