Homework#7 Buzan Kirill
-----------------------
1. Для выполнения задания №1 объявлены следующие переменные:
	- "project_id": null,
	- "source_image_family": null,
	- "machine_type": "f1-micro"
	null - указаны переменные, которые обязательно должны содержать значения
	Для переменной machine_type задано значение по-умолчанию, но это не значит что это значение мы не можем переопределить при выхове packer build

	Packer не поддерживает комментарии, однако их все можно задавать вне блоков [] 
	задается он так:
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
		Переменную, которая имеет занчение по-умолчанию можно не задвать.
		Windows:
		```gcloud
		packer build ^
		-var project_id=lucky-almanac-188814 ^
		-var source_image_family=ubuntu-1604-lts ^
		ubuntu16_with_var.json
	    ```
2. В задании два хочется отметить:
   1) Packer умеет работать со списками. Для того чтобы задать список, значения необходимо поместить в []. Например, tags:
	   "tags": ["puma-server"]
	   значения можно перечислять через запятую: "tags": ["puma-server","https"]
   2) Packer имеет хорошую документацию
   3) Перед build всегда проверяем командой validate конфигурационные файлы. validate поддерживает полный синтаксис команды build, т.е. можно указывать файл с переменными или переменные указывать в самой команде
   3) Важно понимать, что Packer создает образ и настройки которые мы указываем в packer, касающихся сети, типа машины и т.п. - все применяется для виртуальной машины, которая будет запущена для создания образа!

3. Задание получилось интересным. Никогда раньше не использовал pscker, поэтому загадкой была возможность копирования файла с локального диска в образ. Но оказадось все предельно просто:
	```packer
	{
       "type": "file",
       "source": "files/app_puma.service",
       "destination": "app_puma.service"
    },
    ```
	Откуда берем файл и куда его положить.
	   
	"Запченный" образ подразумевает, что после создания экземпляра образа, мы получим полностью рабочий инстанс с настроенным окружением и приложениями. MongpDB изначально в презентации запускается с помощью systemctl, 
	постарался сделать тоже самое для app_puma. Для этого в каталог files был помещен файл *app_puma.service*, в котором заданы параметры для запуска приложения с помощью systemctl.
	Сам сервис запускается в скрипте *startup.sh* из каталога files. Так же скрипт используется для установки самих приложений.
	После работы скрипта в домашнем каталоге пользователя appuser можно посмотреть логи его работы:
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
