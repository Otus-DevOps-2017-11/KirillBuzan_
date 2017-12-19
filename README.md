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
