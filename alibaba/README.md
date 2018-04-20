# digitalresistance

Если будут проблемы с настройкой пишите: @flash286
- Установите зависимости sudo pip install -r requirements.txt
- Положите ключи для доступа к alibaba в файл credentials.py
- Запускайте ./main.py path/to/rkn.dump.xml region-id

Скрипт пройдется по всем вашим серверам и проверит IP адреса на предмет доступности, если какие-то из них забанены, заменит на новые, открытые