#!/bin/bash
set -e

# коприуем докер файл с атрибутом PROJECT_PROFILE на удаленный сервер
echo ">>>>>>> copying a correct compose file <<<<<<<"
scp -o "StrictHostKeyChecking no" docker/docker-compose.${PROJECT_PROFILE}.yml \
    ${REMOTE_USER}@${REMOTE_HOST}:${PROJECT_DIR}/docker-compose.yml

# копируем .env файл на удаленный сервер
scp -o "StrictHostKeyChecking no" .env \
    ${REMOTE_USER}@${REMOTE_HOST}:${ENV_DIR}/

echo "copy done!"

# в переменную назначаем атрибуты для docker-compose
COMPOSE_OPTS="-f ./docker-compose.yml -p test_devops_${PROJECT_PROFILE}"


echo ">>>>>>> starting containers on the remote server <<<<<<<"
# подключаемся к удаленному серверу
ssh ${REMOTE_USER}@${REMOTE_HOST} -o "StrictHostKeyChecking no" << EOF
    # переходим в папку в которую скопировали докер файл
    cd ${PROJECT_DIR}

    echo ">>>>>>> docker-compose pull/down/up <<<<<<<"
    # закачиваем докер контейнеры из docker hub
    docker-compose ${COMPOSE_OPTS} pull
    # останавливаем предыдущие запущенные контейнеры
    docker-compose ${COMPOSE_OPTS} down
    # запускаем только что скачанные контейнеры (-d в фоновом режиме)
    docker-compose ${COMPOSE_OPTS} up -d

    #echo ">>>>>>> Remove trash <<<<<<<"
    # очищаем от напившегося мусора от деплоя (docker volume и docker image)
    docker volume ls -qf dangling=true | xargs -r docker volume rm
    docker images --filter "dangling=true" -q --no-trunc | xargs -r docker rmi
    docker images | grep "none" | awk '/ / { print $3 }' | xargs -r docker rmi
EOF

echo "Done!"
exit 0
