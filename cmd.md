# Inception -- Checklist de Avaliação Rápida (42)

Este documento é uma **versão melhorada do comandos.md**, organizada
para ser usada durante a defesa do projeto.

Contém:

-   Checklist **30 segundos**
-   Comandos agrupados por **serviço**
-   Testes de **rede, volumes e TLS**
-   Lista de **erros que reprovam imediatamente**

------------------------------------------------------------------------

# 1. Checklist rápido (30 segundos)

Execute estes comandos primeiro:

    docker ps
    docker network ls
    docker volume ls
    curl http://localhost
    curl -k https://localhost
    openssl s_client -connect localhost:443

Verificações esperadas:

-   nginx, wordpress e mariadb rodando
-   rede docker criada
-   volumes existentes
-   HTTP **não responde**
-   HTTPS responde
-   TLS ativo

------------------------------------------------------------------------

# 2. Containers

  Comando               O que verifica
  --------------------- ------------------------------
  `docker ps`           containers em execução
  `docker compose ps`   status dos serviços
  `docker images`       imagens buildadas localmente

Containers esperados:

    nginx
    wordpress
    mariadb

------------------------------------------------------------------------

# 3. Rede Docker

  Comando                              O que verifica
  ------------------------------------ -----------------------
  `docker network ls`                  rede docker criada
  `docker network inspect <network>`   containers conectados

Exemplo:

    docker network inspect inception

------------------------------------------------------------------------

# 4. Volumes

  Comando                            O que verifica
  ---------------------------------- --------------------
  `docker volume ls`                 volumes existentes
  `docker volume inspect <volume>`   caminho do volume

Exemplo:

    docker volume inspect wordpress_data

Resultado esperado inclui:

    /home/login/data/wordpress

------------------------------------------------------------------------

# 5. Teste NGINX / HTTPS

  Comando                                     O que verifica
  ------------------------------------------- -------------------
  `curl http://localhost`                     HTTP deve falhar
  `curl -k https://localhost`                 HTTPS funcionando
  `openssl s_client -connect localhost:443`   certificado TLS

TLS esperado:

    TLSv1.2 ou TLSv1.3

------------------------------------------------------------------------

# 6. Testar WordPress

  -----------------------------------------------------------------------------------------------
  Comando                                                     O que verifica
  ----------------------------------------------------------- -----------------------------------
  `curl -k https://localhost`                                 site responde

  `docker exec wordpress wp core is-installed --allow-root`   wordpress instalado

  `docker exec wordpress wp user list --allow-root`           usuários criados
  -----------------------------------------------------------------------------------------------

Testes manuais:

-   login no painel admin
-   criar comentário
-   editar página

------------------------------------------------------------------------

# 7. Testar MariaDB

  ----------------------------------------------------------------------------------
  Comando                                        O que verifica
  ---------------------------------------------- -----------------------------------
  `docker exec -it mariadb mysql -u root -p`     login root

  `docker exec -it mariadb mysql -u <user> -p`   login usuário wordpress
  ----------------------------------------------------------------------------------

Dentro do banco:

    SHOW DATABASES;

------------------------------------------------------------------------

# 8. Testar persistência

  Comando                 O que verifica
  ----------------------- ------------------
  `docker compose down`   parar containers
  `docker compose up`     subir novamente
  abrir WordPress         dados permanecem

Se os dados desaparecerem → volume está errado.

------------------------------------------------------------------------

# 9. Testes de segurança

  Comando                  O que verifica
  ------------------------ --------------------------------
  `nc -z localhost 3306`   MariaDB não deve estar exposto
  `nc -z localhost 9000`   PHP‑FPM não deve estar exposto

------------------------------------------------------------------------

# 10. Erros que fazem reprovar imediatamente

Se qualquer um ocorrer, a avaliação termina:

-   usar `network_mode: host`
-   usar `links:`
-   usar `tail -f /dev/null`
-   usar `sleep infinity`
-   usar imagens prontas do DockerHub
-   WordPress pedindo instalação
-   MariaDB acessível sem senha
-   HTTP porta 80 funcionando
-   dados não persistem após reboot

------------------------------------------------------------------------

# 11. Fluxo completo de avaliação

1.  clonar repositório
2.  executar `make`
3.  verificar containers
4.  verificar rede
5.  verificar volumes
6.  testar HTTPS
7.  testar WordPress
8.  testar MariaDB
9.  reiniciar containers
10. confirmar persistência
