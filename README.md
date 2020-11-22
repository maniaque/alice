## Что это?

Примеры инфраструктурного кода для создания виртуальной машины в разных облачных провайдерах.

## Как этим пользоваться?

0. Добавляем ключ из директории keys/ssh в `ssh-agent`

```
ssh-add keys/ssh/id_rsa
```

1. Инициализируем terraform

```
./terraform.init <provider>
```

2. Раскатываем инфраструктуру

> **NOTE:** Для Mail.Ru нужно скачать и положить в директорию `terraform/mail` файл `openstack_provider.tf`

```
./terraform.do apply <provider>
```

3. Раскатываем туда демонстрационный контейнер

```
ansible-playbook -i inventory ansible/site.yml
```
