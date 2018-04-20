Скрипты для быстрого разворачивания фермы докер контейнеров в Azure.
## Что должно быть установлено на машине
1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
1. [Terraform](https://www.terraform.io/intro/getting-started/install.html)
1. [Ansible](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
## Как пользоваться
```
git clone git@github.com:dimk0/azure-resistance.git
cd azure-resistance
bash resist.sh
```
Сначала скрипт попросит ввести название docker image, который будем разворачивать:
```
var.docker_image
  Enter a value:
```

Если вы не залогинены в Azure CLI, то при первом запуске будет сообщение:
> To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code XXXXXXXX to authenticate.

Нужно пройти по ссылке и ввести код, после этого скрипт продоложит работу автоматически.

Перед созданием ресурсов скрипт выведет план и запросит подтверждение:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```
## FAQ
### Как изменить конфигурацию и количество машин
Нужно отредактировать эту секцию в файле `ansible/generate.yml`:
```
azure_infra:
  - { vm_location: "brazilsouth", vm_size: "Standard_A2", vm_count: 5 }
  - { vm_location: "canadaeast", vm_size: "Standard_D2s_v3", vm_count: 5 }
  - { vm_location: "centralindia", vm_size: "Standard_D2s_v3", vm_count: 5 }
  ...
```
Конфигурация по умолчанию разворачивает по 5 двухъядерных машин в 17 локациях, т.к. дефолтная квота в Azure — до 10 ядер на локацию. Чтобы увеличить квоту, нужно обратиться в саппорт.
### Как узнать, какие есть локации
```
az account list-locations
```
### Как узнать, какие конфигурации VM доступны в локации
```
az vm list-sizes -l japaneast
```
### Как пересоздать ферму
```
bash destroy.sh
bash resist.sh
```
