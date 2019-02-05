Деплой в Travis CI

1. Подготовка
    - Войдите в https://travis-ci.org, используя регистрационные данные github
    - На странице https://travis-ci.org/account/repositories пометьте галочкой нужный репозиторий для интеграции с сервисом
    - Перейдите во вкладку settings отмеченного репозитория
    - Во вкладке Environment Variables добавьте переменные окружения для работы скриптов (.travis.yml и deploy.sh):
        - ```DOCKER_USER``` - Имя пользователя docker hub
        - ```DOCKER_PASSWORD``` - пароль docker hub
        - ```REMOTE_HOST``` - адрес удаленного сервера для деплоя
    - Клонируйте репозиторий github на локальную машину
    - Скопируйте скрипты .travis.yml и deploy.sh в корень вашего репозитория
    - Настройте .travis.yml для своего проекта: 
        - Нахождение docker-compose файлов в проекте
        - В блоке для деплоя указать переменные:
            - ```REMOTE_USER``` - имя пользователя удаленного сервера
            - ```PROJECT_DIR``` - папка проекта на удаленном сервере
            - ```ENV_DIR``` - папка с файлом .env на удаленном сервере
            - ```PROJECT_PROFILE``` - назначение деплоя проекта (stage, dev, prod)
    - Для работы скрипта deploy.sh на удаленной машине добавьте публичный ssh ключ в ~/.ssh/authorized_keys

2. Устанавливаем на локальной машине travis:

    - Установка для разных операционных систем подробно описана тут: https://github.com/travis-ci/travis.rb#installation

3. Генерируем или берем готовый приватный ssh-ключ:
    - Генерация ssh-ключа (описание для Ubuntu):
        - Введите команду:
            ```
            ssh-keygen
            ```
        - Команда предложит выбрать куда сохранить ключ (если вы раньше не создавали ключей, то оставьте поле пустым)
        - После этого появится:
            ```
            Enter passphrase (empty for no passphrase):
            ```
            - Оставьте поле пустым. 
                - Если хотите использовать passphrase, то .travis.yml нужно изменить, т.к. команда ssh-add будет запрашивать passphrase. 
                    Для это нужно (Будем считать, что id_rsa лежит в текущем каталоге):
                    - Добавьте в Environment Variables (settings репозитория в travis CI):
                        - ```SSH_PASSPHRASE``` - passphrase использованная при создании ssh-ключа
                    - Создайте скрипт ```expect.sh``` со следующим содержимым:
                        ```
                        #!/usr/bin/expect

                        #
                        # Интерактивный режим для любых программ
                        #
                        
                        # лимит времени выполнения
                        set timeout 3
                        
                        # объявляем переменные
                        set password [lindex $argv 0]
                        
                        # запускаем программу
                        spawn ssh-add id_rsa
                        
                        # ждем этого приглашения, на что отвечаем паролем
                        expect "Enter passphrase for id_rsa:" { send "$password\r" }
                        
                        expect {
                          # если выскочило это, то пароль не верен, выходим с ошибкой
                          "Bad passphrase, try again for id_rsa:" { exit 1 }
                          # выходим без ошибки
                          eof { exit 0 }
                        }
                        ```
                    - В файле .travis.yml в before_install добавляем:
                        ```
                        sudo apt-get install expect
                        ```
                    - Также в файле .travis.yml вместо строчки: 
                        ```
                        ssh-add ~/.ssh/id_rsa
                        ```
                    - Добавляем:
                        ```
                        chmod +x ./expect.sh
                        ./expect.sh $SSH_PASSPHRASE
                        ```
        - Ключ сгенерирован!
 
    - Копируем приватный ключ id_rsa в корень репозитория

4. Кодируем приватный ключ:
    - Логинимся в travis:
        - Используем логин и пароль от github
            ```
            travis login
            ```
    - Кодируем ключ:
        ```
        travis encrypt-file id_rsa --add
        ```
        Флаг --add автоматически добавит в .travis.yml (в before_install:) команду на расшивровку файла
        Появится файл id_rsa.enc, его оставляем вместе со скриптами travis CI
        ПОСЛЕ КОДИРОВКИ С ФЛАГОМ --add ОБЯЗАТЕЛЬНО РАССТАВИТЬ ТАБЫ КАК БЫЛО ДО КОДИРОВКИ В .travis.yml, ИНАЧЕ ВСЕ УПАДЕТ!
    - Удаляем файл id_rsa

5. Пушим проект на github

6. Для проверки и наблюдения за сборкой travis CI зайдите на https://travis-ci.org/<имя пользователя>/<название репозитория>

7. Использованные материалы:
    - https://oncletom.io/2016/travis-ssh-deploy/
    - https://gist.github.com/jesgs/7815f791c98ea2f3e82c51f5c66b6ce1
    - https://gist.github.com/nickbclifford/16c5be884c8a15dca02dca09f65f97bd
    - https://medium.com/mobileforgood/coding-tips-patterns-for-continuous-integration-with-docker-on-travis-ci-9cedb8348a62
    - https://medium.com/mobileforgood/patterns-for-continuous-integration-with-docker-on-travis-ci-71857fff14c5
    - https://medium.com/mobileforgood/patterns-for-continuous-integration-with-docker-on-travis-ci-ba7e3a5ca2aa