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
