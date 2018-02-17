[![Build Status](https://travis-ci.org/Otus-DevOps-2017-11/KirillBuzan_infra.svg?branch=ansible-3)](https://travis-ci.org/Otus-DevOps-2017-11/KirillBuzan_infra)

Homework#13 Buzan Kirill
-----------------------
Домашнее задание заставило пересмотреть свой подход к выолнению домашних заданий. VirtualBox внутри VirtualBox'a не поднялся, пришлось делить диск и ставить Centos отдельно. Это доставило хлопот, но зато теперь, надеюсь, избавлюсь от описок, потерь, которые иногда происходили при переносе. Теперь в качестве GUI Git'a использую GitKraken, привыкаю к нему.
Настройка и установка VirualBox, Vagrant, Travis на Centos проблем не вызвала. Заодно повторил настройку всего окружения, включая terraform, packer, git :)))
На всякий случай сохраню:
#### 1. Уставнока
```bash
sudo yum -y install gcc dkms make qt libgomp patch
sudo yum -y install kernel-headers kernel-devel binutils glibc-headers glibc-devel font-forge

#VB репозиторий
install virtualbox
cd /etc/yum.repos.d/
wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
yum -y install VirtualBox-5.2

# Запуск kernel version
ls /usr/src/kernels
uname -r

# build the virtualbox kernel module
export KERN_DIR=/usr/src/kernels/$(uname -r)
/sbin/rcvboxdrv setup

# install vagrant
yum -y install https://releases.hashicorp.com/vagrant/2.0.2/vagrant_2.0.2_x86_64.rpm

# install travis
# Пришлось ставить ruby для установки gem. ruby пришлось собирать, так как yum install ruby приводило к установке версии 2.0, для установки travis нужна новее, поставил ruby 2.3.1
yum -y install zlib zlib-devel openssl-devel
cd /usr/src/
wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.1.tar.gz --no-check-certificate
tar -xzvf ruby-2.3.1.tar.gz 
cd ruby-*
./configure 
make
make install
gem install travis
```
#### 2. Vagrantfile
В рамках домашней работы был создан файл Vagrantfile для развертывания 2 виртуальных машин(appserver, dbserver).
Так же создан провиженинг к ролями app и db. 

#### 3. Тест порта 27017
Для роли db создан дополнительный тест для проверки (ansible/roles/db/molecule/default/tests/test_default.py), что порт 27017 слушается:
```yml
# check if db listen 27017 port
def test_db_listen_port(host):
    listen_port = host.socket("tcp://0.0.0.0:27017")
    assert listen_port.is_listening
```

#### 4. Paker
Для работы packer с ролями ansible, внес изменения в файлы (каталог packer) packer_app.json и packer_db.json соответственно:
```json
    "provisioners": [
        {
            "type": "ansible",
            "extra_arguments": ["--tags","ruby"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH=../ansible/roles"],
            "playbook_file": "../ansible/playbooks/packer_app.yml"
        }
    ]
```
```json
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "../ansible/playbooks/packer_db.yml",
            "extra_arguments": ["--tags","install"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH=../ansible/roles"]
        }
    ]
```
Иначаче apcker не видел роли.

#### 5. nginx
Дополнил конфигурацию Vagrant для корректной работы проксирования приложения с помощью nginx в блоке провижининга app.vm.provision:
Vagrantfile
```yml
ansible.extra_vars = {"deploy_user" => "ubuntu",
        nginx_sites: {
          default: [
            "listen 80",
            "server_name reddit",
            "location / {proxy_pass http://127.0.0.1:9292;}"
          ]	
        }
      }
```
#### 6. Роль db в отдельном репозитории
Вынес роль db в отдельный репозиторий:
https://github.com/Otus-DevOps-2017-11/KirillBuzan_infra_db

Протестировал, что роль без проблем скачивается из репозитория. Для этого добавил в файл requirements.yml в каталогах stage и prod:
```yml
- src: https://github.com/Otus-DevOps-2017-11/KirillBuzan_infra_db.git
  name: db
  version: master
```
Установка роли прошла успешно:
```bash
ansible-galaxy install -r requirements.yml
```
Так как тестированрие будет проводиться для GCE, а не Vagrant выполнил удаление каталога molecule из вынесенной роли db и выполнил переинициализирование molecule:
```bash
molecule init scenario --scenario-name default -r db -d gce
```
Шаги работы с travis описаны в https://github.com/Otus-DevOps-2017-11/KirillBuzan_infra_db


Homework#12 Buzan Kirill
-----------------------
#### 1. Роли
Созданы две роли с помощью конмады 
```bash
ansible-galaxy init [имя_роли]
```

1) app. Каталог /ansible/roles/app
2) db. Каталог /ansible/roles/db

В роли перенемены таски, шаблоны, переменные и хендлеры
Для вызова ролей изменены файлы app.yml и db.yml. Теперь эти файлы необходимы только для определения хостов и вызова ролей для этих хостов.

Пересоздана инфраструктура. Выполнен ansible скрипт site.yml. Проверка прошла успешно.

#### 2. Окружения
Созданы два окржуения:
1) prod. Промышленная среда. Каталог /environments/prod/
2) stage. Тестовая среда. Каталоге /environments/stage/
Для каждой среды определны файлы inventory - где определны хосты

В файле ansible.cfg определен inventory файл который используется по-умолчанию: inventory = ./environments/stage/inventory

Параметризация конфигурации ролей за счет переменных дает нам возможность изменять настройки конфигурации, задавая нужные значения
переменных. Ansible позволяет задавать переменные для групп хостов, определенных в инвентори файле.
Произведена параметризация ролей с помощью group_vars. 
Создан каталог group_vars в каждом каталоге окружения:
1) /environments/prod/group_vars
2) /environments/stage/group_vars

Каждый каталог group_vars содержит:

1) app

Определена переменная db_host - внутренний ip-адрес сервера БД. 

2) db

Определена переменная mongo_bind_ip

3) all

Определна переменная env, которая достуна всем хостам. Значение определно в каждом окружении свое: prod или stage соответственно. Необходима для вывода информации об используемом окружении в debug 

#### 3. Организация структуры директорий
Созданы каталоги:
1) playbooks - помещены все используемые плейбуки, которые находились в корне каталога ansible.
2) old - содержит каталоги и файлы, которые был созданы на начальной стадии проекта ansible. Не исользуются в текущей конфигурации проекта.

#### 4. ansible.cfg
Произведено "улучшение" файла ansible.cfg.
1) Добавлено определение каталога, где содержатся роли:
```ansible
[defaults]
roles_path = ./roles
```

2) Отключено создание .retry файлов:
```asnible
[defaults]
retry_files_enabled = False
```

3) Включим постоянный вывод diff при изменениях. Количество строк контекста - 5.
```ansible
[diff]
always = True
context = 5
```
Проверка осуществлена с применением скрипта ansible site.yml к окржуением stage и prod.
При использовании окружения prod указан явно файл с inventory:
```bash
ansible-playbook -i environments/prod/inventory playbooks/site.yml
```
В debug была выведена информация об используемом окружении (prod/stage):
```
TASK [db : Show info about the env this host belongs to]
*********************************************
ok: [dbserver] => {
"msg": "This host is in prod environment!!!"
}

TASK [db : Show info about the env this host belongs to]
*********************************************
ok: [dbserver] => {
"msg": "This host is in stage environment!!!"
}
```
Проверка произведена успешно. 

#### 5. Community roles
Использована ролья jdauphant.nginx
```bash
ansible-galaxy install -r environments/stage/requirements.yml
```
Добавлена возможность использовать порт 80, при развертывании инфраструктуры. Изменен модуль app: /terraform/modules/app/main.tf. Так же определны переменные.
Для переадресации nginx на приложение reddit-app, которое слушает порт 9292, вносятся изменения в переменную app обоих окружений prod и stage.
После развертывания новой инфраструктуры и прогона скритп site.yml приложение доступно по двум портам: 9292 и 80

#### 6. Задание со звездочкой
Для работы с динамическоим inventory разнесем gce.py и gce.ini по каталогам окружений: prod и stage.
Определим inventory по-умолчанию в файле ansible.cfg
```ansible
[defaults]
inventory = ./environments/stage/gce.py
```
Изменены плейбуки app.yml и db.yml. Определены несколько хостов, чтобы можно было использовать как динамичыеский инвентори, так и статический:
app.yml
```yml
hosts:
  - app
  - tag_reddit-app
```

db.yml
```yml
hosts:
  - db
  - tag_reddit-db
```

Проверка успешна.

Задал переменную db_host конкретным значением: 10.132.0.2
Не получилось определить переменную db_hosts таким образом:
db_host: "{{ hostvars['reddit-db']['gce_private_ip'] | default('10.132.0.2') }}"

В случае динамического инвентори все прекрасно работало, в случае статического выдавалась ошибка:
```ansible
Ansible все равно выдает ошибку:
TASK [app : Add config for DB connection] ************************************************
fatal: [appserver]: FAILED! => {"changed": false, "msg": "AnsibleUndefinedVariable: {{ hostvars['reddit-db']['gce_private_ip'] | default('10.132.0.2') }}: "hostvars['reddit-db']" is undefined"}
```
#### 7. Задание со звездочкой 2
Настроен Travis CI. Создан файл .travis.yml.
Документация: https://docs.travis-ci.com/user/customizing-the-build/#Building-Specific-Branches
Столкнулся с проблемой. Необходимо в site.yml использовать import-playbook вместо include. Иначе получаем ошибку, об отсутствии в файлах app.yml и db.yml определения хостов.
Закомментировал использование файла default.tfstate для terraform c google storage. Возникала ошибка при попытке его получить. Дал права для всех пользователей, но ошибка остаалсь. Пришлось комментировать.


Homework#11 Buzan Kirill
-----------------------
#### 1. Часть первая
Выполнено задание в соответствии с домашним заданием "Homework 11. Расширенные возможности Ansible"
Созданы следующие файлы:
1) reddit_app_one_play.yml
Один playbook и один сценарий. Для запуска нужных тасков на заданной группе хостов нужно использовать опцию --limit для указания группы хостов и --tags для указания нужных тасков.
Проблема такого подхода, состоит в том, что необходимо помнить при каждом запуске плейбука, на каком хосте какие таски нужно применить, и передавать это в опциях командной строки.
Пример:
``` bash
ansible-playbook reddit_app_one_play.yml --limit db --tags db-tag
ansible-playbook reddit_app_one_play.yml --limit app --tags app-tag
ansible-playbook reddit_app_one_play.yml --limit app --tags deploy-tag
```
2) reddit_app_multiple_plays.yml
Один playbook и несколько сценариев. При таком подход управлять хостами стало немного легче, чем при использовании одного сценария. Теперь для того чтобы применить нужную часть конфигурационного кода (сценарий) к нужной группе хостов достаточно лишь указать
ссылку на эту часть кода, используя тег.
Проблема такого полхода: с ростом числа управляемых сервисов, будет возрастать количество различных сценариев и, как результат, увеличится объем плейбука. Это приведет к тому, что в плейбуке, будет сложно разобраться.
Пример:
``` bash
ansible-playbook reddit_app_multiple_plays.yml --tags db-tag
ansible-playbook reddit_app_multiple_plays.yml --tags app-tag
ansible-playbook reddit_app_multiple_plays.yml --tags deploy-tag
```
3) Несколько плейбуков. 
При использовании отдельного плейбука теперь нет необходости использовать теги, так как в плейбуке находится только один сценарий. Для запуска необходимо указать только имя плейбука.
  
  3.1) app.yml
Пример:
``` bash
ansible-playbook app.yml
```
  
  3.2) db.yml
Пример:
``` bash
ansible-playbook db.yml
```
  
  3.3) deploy.yml
Пример:
``` bash
ansible-playbook deploy.yml
```
  3.4) site.yml
Для управления конфигурацией всей нашей инфраструктуры из одного файла, создан файл site.yml. Он включает в себя все остальные плейбуки (app.yml, db.yml, deploy.yml)  
Пример:
``` bash
ansible-playbook site.yml
```

#### 2. Задание со звездочкой
В официальной документации ansible предлагают воспользоваться скриптом gce.py и конфигурационным файлом для него gce.ini. http://docs.ansible.com/ansible/latest/guide_gce.html
Cкачать скрипт и конф файл можно с официального репозитория на github:
https://github.com/ansible/ansible/tree/devel/contrib/inventory

1) Cкачиваем файлы:
wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/gce.py
wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/gce.ini

2) Устанавливаем библиотеки для работы с GCE
``` bash
pip install apache-libcloud
```

3) Предоставлние прав исполнение файла: 
``` bash
chmod +x gce.py
```

Для работы скрипта **gce.py** необходимо:
1) создать сервисный аккаунт и сгенерировать ключ для него. 
Выбрал формат json.
https://console.cloud.google.com/iam-admin/serviceaccounts/project?project=lucky-almanac-188814

2) Скачать сгенерированный файл-ключ. Сегенрирован ключ: Infra-99b176a53b90.json

3) Отредктировать файл gce.ini для конкретного проекта. В репозиторий выложен пример заполнения файла gce.ini.example:
``` ini
[gce]
gce_service_account_email_address = service-account@lucky-almanac.iam.gserviceaccount.com
gce_service_account_pem_file_path = Infra-99b176a53b90.json
gce_project_id = lucky-almanac
gce_zone = europe-west1-b
[inventory]
inventory_ip_type = external
``` 

##### Проверка работоспособности скрипта
Все аргументы запуска скрипта gce.py можно посмотреть в функции:
``` python
def parse_cli_args(self):
        ''' Command line argument processing '''

        parser = argparse.ArgumentParser(
            description='Produce an Ansible Inventory file based on GCE')
        parser.add_argument('--list', action='store_true', default=True,
                            help='List instances (default: True)')
        parser.add_argument('--host', action='store',
                            help='Get all information about an instance')
        parser.add_argument('--pretty', action='store_true', default=False,
                            help='Pretty format (default: False)')
        parser.add_argument(
            '--refresh-cache', action='store_true', default=False,
            help='Force refresh of cache by making API requests (default: False - use cache files)')
        self.args = parser.parse_args()
```

./gce.py --list

Будет выведен список всех хостов в формате json без форматирования

./gce.py --pretty

Будет выведен список всех хостов в формате json с форматированием

./gce.py --host reddit-app --pretty

Будет выведена всю информация по выбранному инстансу в формате json с форматированием. В данной случае по reddit-app

##### Проверим работу Dynamic Inventory
``` bash
ansible all -i gce.py -m ping
```
Результат:
reddit-db | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
reddit-app | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}

##### Dynamic Inventory для проекта с несколькими плейбуками 
Изменим файлы app.yml db.yml deploy.yml для динамического определения хостов.
Сначала я думал, что нужно будет создавать свою выходную переменную для определния хоста, к чему зацепиться, но потом обнаружил, что переменные tag_reddit-app и tag_reddit-db создаются автоматически и содержат названия хостов.
В параметр hosts пропишем соответственно:
**app.yml**
hosts: tag_reddit-app 
**db.yml**
hosts: tag_reddit-db 
**deploy.yml**
hosts: tag_reddit-app

Для динамического получения ip-адреса сервера БД воспользуемся конструкцией: 
db_host: "{{ hostvars['reddit-db']['gce_private_ip'] }}"
изменим файл **app.yml**

### 3. Provision Packer
Созданы следующие файлы:
1) packer/packer_app.json
Запекание образа производится на основе ubuntu-1604. Provision выполняется с помощью ansible скрипта. Производится установка ruby, bundler, build-essenital и выводится информация о версии установленного ПО. 
Образ получит название: reddit-app-{{timestamp}}
Так как в задании со звездочокой был сгенерирован ключ, то для возможности подключения к проекту, необходимо использовать этот ключ:
"account_file": "{{ user `account_file`}}"
Переменная определена в файле variables.json
"account_file": "Infra-99b176a53b90.json"

Так же необходимо создать возможность подключения по ssh (ранее данная возможность была перенесена в задание для terraform при развертывании инстанса).
В настройках firewall проекта gce создано правило default-allow-ssh

Образ создаем с помощью команды:
```bash
packer build -var-file=variables.json packer_app.json
```

2) packer/packer_db.json
Запекание образа производится на основе ubuntu-1604. Provision выполняется с помощью ansible скрипта. Производится установка MongoDB, настройка сервиса mongod и выводится информация о состоянии сервиса mongod. 
Образ получит название: reddit-db-{{timestamp}}
Для работы с проектом, используется ключ Infra-99b176a53b90.json.

Образ создаем с помощью команды:
``` bash
packer build -var-file=variables.json packer_db.json
```

3) ansible/packer_app.yml
Производится установка ruby, bundler, build-essenital и выводится информация о версии установленного ПО. 

4) ansible/packer_db.yml
Производится установка MongoDB, настройка сервиса mongod и выводится информация о состоянии сервиса mongod. 

Для развертывания созданных образов воспользуемся terraform и настроеными перематрами в каталоге /terraform/stage. Перед запуском удалил правило firewall default-allow-ssh
``` bash
terraform apply
```

После развертывания инстансов, запускаем плейбук sity.yml 
web-приложение успешно развернуто и доступно.

Homework#10 Buzan Kirill
-----------------------
#### 1. Файл Inventory
Создал файл inventory в котором задал краткое имя, идентифицирующее хост, и параметры для подключения к этому хосту:
1) appserver
```ansible
appserver ansible_host=35.205.212.75 ansible_user=appuser ansible_private_key=~/.ssh/appuser
```
appserver - краткое имя по которому сможем вызвать применение модуля 
ansible_host - IP-адрес хоста
ansible_user - Пользователь, под которым будет осуществлено подключение
ansible_private_key - Путь до приватного SSL-ключа пользователя

2) Добавил в файл inventory еще один хост dbserver
```ansible
dbserver ansible_host=104.199.30.219 ansible_user=appuser ansible_provate_key=~/.ssh/appuser
```
Файл inventory получился следующего содержания:
```ansible
appserver ansible_host=35.205.212.75 ansible_user=appuser ansible_private_key=~/.ssh/appuser
dbserver ansible_host=104.199.30.219 ansible_user=appuser ansible_provate_key=~/.ssh/appuser
```
Применил выполнение модуля ping для указанных  выше хостов.
1) appserver
```bash
ansible appserver -i ./inventory -m ping
```
appserver - краткое имя, идентифицирующее хост. Указано в файле inventory 
-i ключ, который позволяет определить путь до файла inventory
./inventory - путь до файла inventory, созданного выше
-m ключ который позволяет вызвать модуль
ping - подключаемый модуль

2) dbserver
```bash
ansible dbserver -i ./inventory -m ping
```
Результат выполнения команды:
1) appserver
appserver | SUCCESS => {
  "changed": false,
  "ping": "pong"
}
2) dbserver
dbserver | SUCCESS => {
  "changed": false,
  "ping": "pong"
}

Модуль ping позволяет произвести тестирование подключения к серверу по протоколу SSH, но при этом на хост никакие изменения не вносятся.

#### 2. Файд ansible.cfg
В файле inventory указаны хосты и параметры для подключения к ним. Информация дублируется, а так же приходится заполнять каждый параметр для каждого хоста. Поэтому лучше параметры вынести в отдельный конфигурационный файл ansible.cfg
```ansible
[defaults]
inventory = ./inventory
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
```
Параметр **host_key_checking** отвечает за включение/отключение проверки SSH-ключа на удалённом хосте. По умолчанию проверка включена. 
По умолчанию SSH-клиент при подключении к хосту осуществляют проверку подлинности ключа, если SSH клиент не узнает отпечаток, то он просит подтвердить добавление отпечатка и необходимо набрать yes/no.
Чтобы избежать проблем при подключении к хосту с помощью ansible (производится автоматиеское подключение), отключаем проверку SSH-ключа.

После создания конфигурационного файла, можно изменить файл inventory, удалив параметры для подключения, оставив только IP-адреса хостов.
Содержимое файла inventory:
```ansible
appserver ansible_host=35.205.212.75
dbserver ansible_host=104.199.30.219
```
Проверим вызов модуля ping
```bash
ansible appserver -m ping
```
Теперь нам не нужно задавать путь до файла inventory, так как мы его указали в конфигурационном файле ansible.cfg
Результат:
ansible appserver -m ping
appserver | SUCCESS => {
  "changed": false,
  "ping": "pong"
}

ansible dbserver -m ping
dbserver | SUCCESS => {
  "changed": false,
  "ping": "pong"
}

Содеинение прошло успешно с обоими хостами.

Для выполнения команд на хосте используется модуль command.
```bash
ansible appserver -m command -a uptime
```
Команда для выполнения передается как аргумент для модуля command. Для этого используется опция **-a**

Результат:
ansible appserver -m command -a uptime
appserver | SUCCESS | rc=0 >>
16:16:50 up 2:14, 1 user, load average: 0.00, 0.00, 0.00

ansible dbserver -m command -a uptime
dbserver | SUCCESS | rc=0 >>
16:19:51 up 2:17, 1 user, load average: 0.00, 0.00, 0.00

#### 3. Группы хостов
Для возможности управления группой хостов внесем изменения в файл inventory
```ansible
[app]
appserver ansible_host=35.205.212.75

[db]
dbserver ansible_host=104.199.30.219
```
Теперь можно вызывать модуль не только для одного хоста, а для группы хостов.
Например, добавив в группу [app] оба хоста: appserver и dbserver и вызвав команду:
```bash
ansible app -m ping
```
получим вызов модуля сразу для двух хоств:
appserver | SUCCESS => {
  "changed": false,
  "ping": "pong"
}
dbserver | SUCCESS => {
  "changed": false,
  "ping": "pong"
}

Такого же результата можно было добиться, используя команду 
ansible all -m ping
Применяется для всех хостов, которые описаны в файле inventory

#### 4. YAML inventory
Создал файл inventory.yml 
```YML
---
app:
  hosts:
    appserver:
      ansible_host: 35.205.212.75
db:
  hosts:
    dbserver:
      ansible_host: 104.199.30.219
...
```

Вызовем ansible с модулем ping для **группы хостов app**.
```bash
ansible app -i ./inventory.yml -m ping
```
Результат будет выведен на экран.
Так же можно вызвать для **всех хостов** вызов модуля:
```bash
ansible all -i ./inventory.yml -m ping
```
и для **конкретного хоста**:
```bash
ansible dbserver -i ./inventory.yml -m ping
```

#### 5. Задание со звёздочкой. Inventory.json
Файл json будет выглядеть так:
```json
{
  "app": {
    "hosts": {
      "appserver": {
        "ansible_host": "35.205.212.75"
	  }	
    }
  },
  "db": {
    "hosts": {
      "dbserver": {
        "ansible_host": "104.199.30.219"
      }
    }
  }
}
```
Для версии ansible 2.0 JSON будет быть задан иначе "ключ": [значение]:
```json
{
    "appserver": {
        "hosts": ["35.205.212.75"]
    },
    "dbserver": {
        "hosts": ["104.199.30.219"]
    }
}
```

Выполнил проверку со всеми вариантами:
**Все хосты**:
ansible all -i ./inventory.json -m ping

**Группа хостов app**:
ansible app -i ./inventory.json -m ping

**Хост appserver**:
ansible appserver -i ./inventory.json -m ping

**Группа хостов db**:
ansible db -i ./inventory.json -m ping

**Хост dbserver**:
ansible dbserver -i ./inventory.json -m ping

Результат успешен.

Для динамического запуска inventory можно воспользоваться Python. Который будет выводить файл в json формате.
Создал простой пример. Данные в нем статичны, но вызов динамический.
```python
#!/usr/bin/env python
f_json = open("inventory.json","r")
print(f_json.read())
f_json.close()
```
Выполним проверку для все хостов:
ansible all -i inventory.py -m ping
Будем получен успешный результат выполнения команды ping.

#### 6. Выполнение команд
Повторены все примеры из домашнего задания пункта "выполнение команд".
Необходимо правильно использовать команду shell, так как при ее использовании об идентпатентности придется заботиться самим. 
Т.е. например, если нам необходимо создать каталоги командой, то каталоги будут создаваться каждый раз при использовании shell сриптов. И нам нужно будет контролировать самим этот процесс. Если использовать специальные модули для этого, то проверку состояния наличия каталогов ansible  возьмет на себя.


Homework#9 Buzan Kirill
-----------------------
#### Импорт существующей инфраструктуры в Terraform

Импорт правила firewall default-allow-ssh выполнен корректо.
Но были замечены отличия от презентации:

Происходит не изменение, а удаление с последующим добавлением.Используется последняя версия продукта.
```terrafrom
-/+ destroy and then create replacement

Terraform will perform the following actions:

-/+ google_compute_firewall.firewall_ssh (new resource required)
      id:                       "default-allow-ssh" => <computed> (forces new re
source)
      allow.#:                  "1" => "1"
      allow.803338340.ports.#:  "1" => "1"
      allow.803338340.ports.0:  "22" => "22"
      allow.803338340.protocol: "tcp" => "tcp"
      description:              "Allow SSH from anywhere" => "Allow SSH from any
where.HM#9"
      destination_ranges.#:     "0" => <computed>
      name:                     "default-allow-ssh" => "default-allow-ssh"
      network:                  "https://www.googleapis.com/compute/v1/projects/
lucky-almanac-188814/global/networks/default" => "default"
      priority:                 "65534" => "1000" (forces new resource)
      project:                  "lucky-almanac-188814" => <computed>
      self_link:                "https://www.googleapis.com/compute/v1/projects/
lucky-almanac-188814/global/firewalls/default-allow-ssh" => <computed>
      source_ranges.#:          "1" => "1"
      source_ranges.1080289494: "0.0.0.0/0" => "0.0.0.0/0"
Plan: 1 to add, 0 to change, 1 to destroy.
```

#### Структуризация ресурсов

С помощью Packer создны новые образЫ:
1) reddit-app-base
2) reddit-db-base
на основе ОС ubuntu 16.04
Образ 1 - содержит установелнный Ruby
ОБраз 2 - содержит установонную СУБД MongoDB.
Файлы конфигурации app.json и db.json соответственно добавлены в каталог packer/

В резльутате выолнения данного пункта, конфигцрационный файл main.tf был разбит на три части:
1) app.tf - равертывание VM из образа reddit-app-base
2) db.tf - развертывание VM из образа reddit-db-base
3) vpc.tf - правило фаервола для ssh доступа. Применяется для всех инстнасов нашей сети.

Файл main.tf остался. Он содержит определение провайдера. 

Проверка прошла успешно. Хосты доступны. На них установлено необходимое ПО.

```bash
reddit-app:
gcp_buzan@reddit-app:~$ ruby -v
ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
gcp_buzan@reddit-app:~$ bundle -v
Bundler version 1.11.2
```
```bash
reddit-db:
gcp_buzan@reddit-db:~$ sudo systemctl status mongod
? mongod.service - High-performance, schema-free document-oriented database
   Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2018-01-07 05:25:59 UTC; 4min 8s ago
     Docs: https://docs.mongodb.org/manual
 Main PID: 1208 (mongod)
    Tasks: 19
   Memory: 52.2M
      CPU: 1.578s
   CGroup: /system.slice/mongod.service
           L-1208 /usr/bin/mongod --quiet --config /etc/mongod.conf
Jan 07 05:25:59 reddit-db systemd[1]: Started High-performance, schema-free document-oriented database.
```
Файлы переименованы в *.tf_backup

#### Модули

Создан каталог modules, который содержит подкаталоги:
1) app - содержит модуль приложения
2) db - содержит модуль БД. 
3) vpc - содержит модуль настроек фаервола 

Каждый каталог с модулями содежрит:
main.tf - главный файл
outputs.tf - входные переменные
variables.tf - выходные переменные

Изменен файл main.tf - в него добавлены вызовы модулей.
Terraform еще ничего не знает о созданных модулей, мы только определили пути к модулям.
Для того чтобы terraform загрузил модули к себе, воспользуемся командой terraform get
После чего terraform создаст в своем каталоге .terraform подкаталог module куда поместит в нашем случае ссылки (ярлыки) на каталог с модулями, так как модули у нас располагаются локально, в случае, если модуль располагается удаленно, то terraform скопирует содержимое модуля целиком, забегая вперед, как это произошло с модуляем SweetOps-terraform-google-storage-bucket

Проверка прошла успешно. Хосты доступны. Правила firewall созданы.
Добавил свой description
description = "Allow SSH from anywhere.HM#9"
для firewall чтобы было 100% видны изменения

#### Параметризация модулей

* Если ip не мой, то ошибка подключения по ssh
ssh: connect to host 35.187.189.128 port 22: Connection timed out

* Если ip мой, то подключение проходит успешно

#### Переиспользование модулей
Произвел разделение на prod и stage. 
stage доступен с любым ip-адресом, prod только с указанного в конфигурационном файле

Параметеризированы следующие конфигурации модулей:
1. app:
  
  |Переменная|Описание|
  |----------|--------|
  |machine_type = "${var.machine_type}"| Тип машины|
  |zone         = "${var.zone}"| Зона|
  |tags         = "${var.target_tags}"| Тэги сети. Применяется для инстанса|
  |image = "${var.app_disk_image}"| Образ из которого будет развернута VM app|
  |sshKeys = "appuser:${file(var.public_key_path)}"|Путь до открытой части ключа|
  |private_key = "${file(var.private_key_path)}"| Путь до закрытой части ключа|
  |ports    = "${var.firewall_puma_port}"| Порт на котором доступно приложение после развертывания|
  |source_ranges = "${var.source_ranges}"| Диапазон портов на который применяется правило allow-puma-default в firewall|
  |target_tags   = "${var.target_tags}"| Тэги сети. Применяется для правила allow-puma-default в firewall|

2. db:

  |Переменная|Описание|
  |----------|--------|
  |machine_type = "${var.machine_type}"| Тип машины|
  |zone         = "${var.zone}"| Зона|
  |tags         = "${var.target_tags}"| Тэги сети. Применяется для инстанса|
  |image = "${var.db_disk_image}"| Образ из которого будет развернута VM db|
  |sshKeys = "appuser:${file(var.public_key_path)}"|Путь до открытой части ключа|
  |ports    = "${var.firewall_mongo_port}"| Путь до закрытой части ключа|
  |target_tags = "${var.target_tags}"| Тэги сети. Применяется для правила allow-mongo-default в firewall|
  |source_tags = "${var.source_tags}"| Диапазон портов на который применяется правило allow-mongo-default в firewall|

3. vpc:

|Переменная|Описание|
|----------|--------|
|source_ranges = "${var.source_ranges}"| Диапазон портов на который применяется правило default-allow-ssh в firewall|

4. Файл main.tf prod и stage.

|Переменная|Описание|
|----------|--------|
|variable project| Имя проекта GCP|
|variable region| Регион|
|variable public_key_path| Путь до публичного ключа|
|variable private_key_path| Путь до закрытого ключа|
|variable zone| Зона|
|variable app_disk_image| Имя образа на сонове которого будет создана VM APP|
|variable db_disk_image| Имя образа на сонове которого будет создана VM DB|

Так же создана локальная переменная *local.access_db_tags*
Она содержит тэги для взаимодействия между DB и APP серверами. 
Соответственно у app это target_tags, а у DB source_tags

Ко всем файлам применено форматирование terrafform fmt

#### Задание со звездочкой *
Добавлено хранение state файлв в GCS. Создан сегмент: terraform-hm9. 
Далее используется слудющий путь: terraform/state/default.tfstate.
В файлы main.tf в каталогах prod и stage добавлены строки:
```terraform
terraform {

  backend "gcs" {

    bucket  = "terraform-hm9"

    prefix  = "terraform/state"

  }
}
```
2. Файл state перенесен в другой каталог, осуществлена проверка, что файл state terraform ищет в GCS и что он ялвялется общим для stage и prod.
3. При попытке внести изменения одновременно. Блокировка:
Error: Error locking state: Error acquiring the state lock: writing "gs://terraf
orm-hm9/terraform/state/default.tflock" failed: googleapi: Error 412: Preconditi
on Failed, conditionNotMet
Lock Info:
  ID:        09a2d2d1-5c12-ef54-77cc-130227e5bd14
  Path:
  Operation: OperationTypeApply
  Who:       KIRILL-ПК\KIRILL@KIRILL-ПК
  Version:   0.11.1
  Created:   2018-01-07 09:42:04.2955193 +0000 UTC
  Info:
  
  
#### Задание со звездочкой 2
Добавлены provisioner в модуль APP для создания сервиса puma.services. А так же установки и запуску приложения reddit с помощью puma.services.
Для подключения к БД приложения параметеризирован адресс и порт БД variable database_url
Для того чтобы сформировать файл puma.services с заданными значнеиями, необходимо воспользоваться шаблонами.
Создан файл puma.service.tlp на основе файла puma.service который использовался в предыдущих заданиях. 
Притерпел изменения только параметр ExecStart:
ExecStart=/bin/bash -lc 'DATABASE_URL=${database_address} puma'

В него добавлена переменная задающая URL БД. Значение переменной может бытть задано пользователем или использоваться значение по умолчанию. 

Создание, получение значения переменных и передача этих знчений в шаблон, осуществляется так:
```terraform
data "template_file" "puma-service" {
  template = "${file("${path.module}/files/puma.service.tpl")}"

  vars {
    database_address = "${var.database_url}"
  }
}
```
Так же в provisioner "file" необходимо изменить параметр source (раньше мы указаывали на уже сформированный файл puma.service) на content (файл создается с помощью шаблона, конфигрируется во время работы terrafrom)
```terraform
provisioner "file" {
    content      = "${data.template_file.puma-service.rendered}"
...
```

#### Реестр модулей
После применения модуля в GCS были созданы два бакета. Имена бакетов пришлось задать иначе, не как в презентации. Иначе выдавалсь ошибка.
```terraform
 module "storage-bucket" {
  source = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  name = ["storage-bucket-test-345", "storage-bucket-test2-745"]
}
```
Homework#8 Buzan Kirill
-----------------------
**Самостятельное задание выполнено:**
1. Определил input переменную *private_key_path* для приватного ключа.
   Файл: variables.tf
   ```terraform
   variable private_key_path {
      description = "Path to the private key used for ssh access"
   }
   ```
   Файл: terraform.tfvars Но так как он не публикуется. То пример заполнения можно увидеть в файле: terraform.tfvars.example
   ```terraform
   private_key_path = "~/.ssh/appuser"
   ```
2. Определил input переменную *zone* для задания зоны в ресурсе "google_compute_instance" "app".
   Файл: variables.tf
   ```terraform
   variable zone {
     description = "Zone"
     default     = "europe-west1-b"
   }
   ```
   Значение в файле: terraform.tfvars не задано, в проекте используется значение по умолчанию.
3. Произведено форматирвоание с помощью команды **terrafrom frm** Terraform самостоятельно ищет файл с расширением .tf и производит форматирование в каждом файле.
4. Создан файл terraform.tfvars.example для примера заполнения файла terraform.tfvars с реальными данными.

**Задание со звездочкой**
Если какой-то ключ добавлен "руками", без участия Terraform, то Terraform о нем ничего не знает и просто затирает этот ключ. 
Это нужно помнить и судя по всему управлять ключами программно не является хорошей практикой.
Может быть в некоторых условиях это будет удобно, но не в условиях промышленной высонагруженной среды.

Вставку нескольких ключей я выполнил так: 
```terraform
resource "google_compute_project_metadata" "users" {
	metadata {
	   ssh-keys = "appuser2:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}\nappuser:${file(var.public_key_path)}"
	}
}
```
Но мне хотелось первоначально создать переменную, где будут перечислены пользователей, а с помощью terraform будут добавлятся пары
user и его ключ. Ключ хотел использовать один.
Пытался сделать так:
Переменная users:
```terraform
users = "appuser2,appuser1,appuser"

resource "google_compute_project_metadata" "users" {
	count = "${length(split(",", var.users))}"
	metadata {
	   ssh-keys = "${element(split(",", var.users), count.index)}:${file(var.public_key_path)}"
	}
}
```
Все казалось бы логично и даже команда terraform plan выдавала результат, что будут добавлены три записи, так как я создавал 3 пользователя.
``` terraform
	+ google_compute_project_metadata.users[0]
	id:                <computed>
	metadata.%:        "1"
	metadata.ssh-keys: "appuser2:ssh-rsa ****
	- - - 
	+ google_compute_project_metadata.users[1]
	id:                <computed>
	metadata.%:        "1"
	metadata.ssh-keys: "appuser1:ssh-rsa ****
	- - -
	+ google_compute_project_metadata.users[2]
	id:                <computed>
	metadata.%:        "1"
	metadata.ssh-keys: "appuser:ssh-rsa ****
	- - -
	Plan: 3 to add, 0 to change, 0 to destroy.
```
Но при выполнении команды apply, terraform выдает ошибку в самом конце:
``` terraform
Error: Error applying plan:
1 error(s) occurred:
* google_compute_project_metadata.users[1]: 1 error(s) occurred:
* google_compute_project_metadata.users.1: Error, key 'ssh-keys' already exists
in project 'lucky-almanac***'
```
Terraform сам пытается перезаписать свои же изменения. Получается, что нужно заранее подготовить строку для добавления и сразу внести все значения целиком.
Убил я на это дело еще пол дня... Но ничего не получилось. Пытался через template реализацию сделать:
``` terraform
   data "template_file" "users_sshkey" {
      template = "$${users_key}"
      vars {
         count = "${length(split(",", var.users))}"
         users_key = "$${users_key}\n${element(split(",", var.users), count.index)}:${file(var.public_key_path)}"   
      }
   }
   resource "google_compute_project_metadata" "users" {
      metadata {
         ssh-keys = "${data.template_file.users_sshkey.rendered}"
      }
   }
```
Но terraform не помнит, что было в переменной на предыдущей операции. 
Как мне нужно было выполнить реализацию? Я не верю, что это не возможно сделать)))

При работе с проектом натолкнулся на интересный реурс. Много примеров:
https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
Отсутствие нормальных циклов и использование count показалось очень специфичным. На просторах интернета я не нашел больше вариантов
реализации циклов.

**Задание со звездочкой 2**
Задание огонь. Это пока самая времязатратное домашнее задание из всех) Думал, что меня terraform победит. Но у terraforma хорошая документация оказалась по балансировке. С "циклом" познкомился еще на предыдущем шаге выполнения, поэтому создание инстансов выполнил в цикле. Для такого такой задачи count более, чем достаточно.
Балансиорвку настроил, но приложение на каждом сервере свое и при этом они имею свою собственную БД, поэтому получается, что работать с таким приложением пользовтелю не представляется возможным, но зато у него неплохая отказоустойчивость. 
Каждые 3 секунды, происходит переключение между серверами, таковы настройки, происходит отключение сессии. Но на одном сервере я успел создать пост, поэтому пост, то появляется, то исчезает при обнолвении страницы.

Когда задавал имя инстанса, столкнулся с ошибкой. 
``` terraform
* google_compute_instance.app: Error creating instance: googleapi: Error 400: In
valid value for field 'resource.name': 'reddit-app_0'. Must be a match of regex
'(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)', invalid
```
Использовал символ "_". Что вызвало ошибку. В копилку знаний.

Для вывода информации об IP-адресе балансировщика в outputs добавил переменную balancer_external_ip:
Outputs:

app_external_ip = [
    35.187.189.128,
    104.199.103.253
]
balancer_external_ip = 35.227.200.95

Homework#7 Buzan Kirill
-----------------------
1. Для выполнения задания №1 объявлены следующие переменные:
	- "project_id": null,
	- "source_image_family": null,
	- "machine_type": "f1-micro"
   null - указаны переменные, которые обязательно должны содержать значения;
   Для переменной machine_type задано значение по-умолчанию, но это не значит, что это значение мы не можем переопределить при вызове packer build

   Packer не поддерживает комментарии, однако их все же можно задавать, но только вне блоков []. Задается он так:
   "_comment": "The machine_type default value is f1-micro, but you can set any value when defining machine_type variable",
   В работе использовал в нескольких местах.

   Задать значения обязательным переменным мы можем:
      a) как с помощью файла (в файле variables.json.example показан пример инициализации переменных):
         packer validate -var-file=variables.json ubuntu16.json 
      b) непосредственно в самой команде:
	 пример для Unix:
	    ```gcloud
	    packer build \
	    -var project_id=lucky-almanac-188814 \
	    -var source_image_family=ubuntu-1604-lts \
	    -var machine_type=f1-micro ubuntu16_with_var.json
	    ```
	 Переменную, которая имеет значение по-умолчанию можно не задавать.
	 Windows:
	    ```gcloud
	    packer build ^
	    -var project_id=lucky-almanac-188814 ^
	    -var source_image_family=ubuntu-1604-lts ^
	    ubuntu16_with_var.json
	    ```
2. В задании два хочется отметить:
   1) Packer умеет работать со списками. Для того чтобы задать список, значения необходимо поместить в []. 
   Например, tags:
      "tags": ["puma-server"]
      значения можно перечислять через запятую: "tags": ["puma-server","https"]
   2) Packer имеет хорошую документацию;
   3) Перед build всегда проверяем командой validate конфигурационные файлы. validate поддерживает полный синтаксис команды build, т.е. можно указывать файл с переменными или переменные указывать в самой команде;
   3) Важно понимать, что Packer создает образ и настройки которые мы указываем в packer, касающихся сети, типа машины и т.п. - все применяется для виртуальной машины, которая будет запущена для создания образа!

3. Задание получилось интересным. Никогда раньше не использовал packer, поэтому загадкой была возможность копирования файла с локального диска в образ. Но оказалось все предельно просто:
   ```packer
   {
      "type": "file",
       "source": "files/app_puma.service",
       "destination": "app_puma.service"
    },
    ```
   Откуда берем файл и куда его положить.
	   
   "Запченный" образ подразумевает, что после создания экземпляра образа, мы получим полностью рабочий инстанс с настроенным окружением и приложениями. MongpDB изначально в презентации запускается с помощью systemctl, постарался сделать тоже самое для app_puma. Для этого был создан файл *app_puma.service*, в котором заданы параметры для запуска приложения с помощью systemctl. Размещается в каталоге files.
   Сам сервис запускается в скрипте *startup.sh* из каталога files. Так же скрипт используется для установки самих приложений. После работы скрипта в домашнем каталоге пользователя appuser можно посмотреть логи его работы:
	   *install_ruby.log* - установка ruby
	   *install_mongo.log* - уставнока MongoDB. Создание сервиса для управления запуском/остановом MongoDB
	   *deploy.log* - запуск приложения и создание сервиса для управления запуском и остановом приложения app_puma
	   
После создания экземпляра образа reddit-full-1514326289 в браузере отобразилась страница приложения.	   
	   
4. Скрипт находится в каталоге *create-reddit-vm.sh* и позволяет создавать инстанс с именем reddit-full	 
   ```bash
   !#/bin/bash
   set -e
   gcloud compute instances create "reddit-full" \
   --zone "europe-west1-b" \
   --machine-type "g1-small" \
   --subnet "default" \
   --tags "puma-server" \ 
   --image "reddit-full-1514326289" \
   --image-project "lucky-almanac-188814" \
   --boot-disk-size "10" \
   --boot-disk-type "pd-standard" \
   --boot-disk-device-name "reddit-full" \
   --restart-on-failure
   ```
	   
Homework#6 Buzan Kirill
-----------------------
Из задания не ясно, как предполагается добавить скрипт при создании инстанса: из локальной дирректории или из githuba.
Попробовал оба способа.
Ссылка на документацию: https://cloud.google.com/compute/docs/startupscript
1) Скрипт из локального хранилища:
```gcloud
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup.sh
  ```
2) Скрипт из репозитория github. Ссылка на файл должна быть RAW, иначе не подхватит.
```gcloud
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata startup-script-url=https://raw.githubusercontent.com/Otus-DevOps-2017-11/KirillBuzan_infra/Infra-2/startup.sh
```
Для всех файлов *.sh права 750

Homework#5 Buzan Kirill
-----------------------
<table>
  <tr>
    <td colspan=4 align=center> 
      <b> Конфигурация стенда </b>
    </td>
  </tr>
  <tr>
    <td>
      <b>Host</b>
    </td>
    <td>
      <b>Zone</b>
    </td>
    <td>
      <b>Internal IP</b>
    </td>
    <td>
      <b>External IP</b>
    </td>
  </tr>
  <tr>
    <td>
      bastion
    </td>
    <td>
      europe-west1-d
    </td>
    <td>
      10.132.0.2
    </td>
    <td>
      146.148.20.172
    </td>
  </tr>  
    <tr>
    <td>
      someinternal
    </td>
    <td>
      europe-west1-d
    </td>
    <td>
      10.132.0.3
    </td>
    <td>
      null
    </td>
  </tr> 
</table

***********
Задание 1:
***********
1. Генерируем ключ с помощью команды ssh-keygen. Важно отметить, что ключ должен иметь права 600 (-rw-------), иначе получим ошибку: *Unprotected private key file*
2. Добавляем ключ в SSH Agent - настройка Forwarding. 
3. Производим проброс авторизации. Буду использовать *ProxyJump* (коротко и быстро):
```bash
$ ssh -J appuser@146.148.20.172 appuser@10.132.0.3 
```
более развернутый вид приведен для разъяснения доп.задания.
```bash
$ ssh -oProxyJump=appuser@146.148.20.172 appuser@10.132.0.3 
```
В команде нужно указывать пользователей под которыми происходит коннект. Так же для работы ssh в режиме проброcа авторизации, необходмио чтобы на серверах 146.148.20.172 и 10.132.0.3 существовал открытый ключ в ~/.ssh/authorized_keys

*********
Дополнительное задание к заданию 1
*********
Необходимо использовать Alias. Это в первую очередь удобно, избавляет от написания больших dns-имен и уменьшает количество символов команд для работы с сервером.
1. Создадим файл config в каталоге ~/.ssh/
2. Содержимое файла:
```
Host bastion
   Hostname 146.148.20.172
   User appuser

Host internalhost
   Hostname 10.132.0.3
   User appuser
   ProxyJump bastion
```   
3. Настраиваем права 600 (-rw-------). Иначе ошибка Bad owner or permission
4. Теперь вместо команды:
```bash
$ ssh -A appuser@146.148.20.172 
```
используем команду 
```bash
$ ssh bastion
```
Вместо команды:
```bash
$ ssh -J appuser@146.148.20.172 appuser@10.132.0.3
```
команду:
```bash
$ ssh internalhost
```
**********
После установки соединения VPN (Virtual Private Network) появляется возможность подключения к удаленному серверу 10.132.0.3 напрямую с локальной машины. Создается частаня виртуальная сеть.
