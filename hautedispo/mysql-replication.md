# Replication mysql

## Présentation

Mysql est un serveur de base de données relationnel proposant un moteur transactionnel performant et robuste (innodb).

Mysql propose en built-in de la réplication, elle consiste en la transmission depuis le serveur "maître" des écritures sur des "esclave".

A l'initialisation les structures de données et les données doivent être identique sur le maitre et les esclaves, Le maitre transmet alors ses `bin-log` vers les esclaves

Deux formats de bin-log existent :

- **Statement**-Based Replication SBR : les requêtes sont transmises
- **Row**-Based Replication RBR : les lignes modifiées sont transmises
- Seulement deux format, mais ils peuvent être aussi être conbiné (**Mixed**) Mysql choisi le forma de réplication optimum suivant les cas, du coup ça fait trois.

En mode Row, Mysql s'adapte suivant les actions d'écriture (les créate table sont bien sur transmis en statement) c'est donc déja un mode combiné.

## Mise en oeuvre

- **tout serveur est master** à partir du moment ou il dispose d'un server-id (non null) et d'un nommage des bin-log (dans le fichier my.cnf) :

  ```bash
  server-id     = 1
  log_bin       = /var/lib/mysql/log-bin.log
  binlog_format = row
  ```

- le slave doit disposer d'un compte pour se connecter au master et connaitre la position d'ou démarre la réplication :

  ```bash
  mysqlmaster> SHOW MASTER STATUS\G
  ************************ 1. row ************************
           File: log-bin.000008
           Position: 1507
           Binlog_Do_DB: db1,db2
  
  mysqlmaster> GRANT REPLICATION SLAVE ON *.* TO repl_user@192.168.56.204 IDENTIFIED BY 'rick&morty';
  
  mysqlslave> CHANGE MASTER TO MASTER_HOST='192.168.56.203',
   -> MASTER_USER='repl_user',
   -> MASTER_PASSWORD='rick&morty',
   -> MASTER_LOG_FILE='log-bin.000008',
   -> MASTER_LOG_POS=1507;
  mysqlslave>
  ```

- Synchronisation du slave :
  - lock de la base master le temps de lancer un dump (restez connecter)

  ```bash
  mysqlmaster> RESET MASTER;
   -> FLUSH TABLES WITH READ LOCK;
   -> SHOW MASTER STATUS;
  ```

  - dump de la base depuis le slave :

  ```bash
  mysqlslave> STOP SLAVE;
  ```

  ```bash
  $ mysqldump -h master -u root -p --all-databases > /tmpdir/masterdump-000008-1507.sql
  $
  ```

  - release du lock (**il n'est pas nécessaire d'attendre la fin du dump**)

  ```bash
  mysqlmaster> UNLOCK TABLES;
  ```

  - On peu alors relancer la réplication sur le slave

  ```bash
  mysqlslave> RESET SLAVE;
  mysqlslave> CHANGE MASTER TO MASTER_LOG_FILE='log-bin.000008', MASTER_LOG_POS=1507;
  mysqlslave> START SLAVE;
  ```

  Bien sur pour une base de données plus volumineuse on utilisera à la place du dump une sauvegarde à chaud des bin-files (avec l'outil xtrabackup par exemple) puis une restoration sur le slave avant de relancer la réplication.

## Consistence et incidents courant

La réplication est fragile. Les opérations éffectuées sur le maitre ont toutes été exécutées et sont donc valide. Un rejet de l'une d'entre elle sur un slave (exemple : update sur un enregistrement inexistant) bloque la réplication sur ce slave par sécurité.

Il arrive fréquement que, par accident, une écriture est effectué sur un slave, il deviens alors inconsistent. c'est pourquoi dans la plupart des cas on la démarre en mode readonly.

```bash
mysql> set GLOBAL read_only=true;
```

Mais cela n'est pas toujours possible. Dans tout les cas, il conviens, afin d'assurer la consistence des données pour l'application, de surveiller (entre autre) que la réplication fonctionne bien (Slave_SQL_Running: Yes) et que le délai de réplication est acceptable (Seconds_Behind_Master: N). L'application dois aussi savoir s'adapter à ces cas (basculer ses lecture sur le maitre lorsque le slave est en trop en retard).

On consulte l'état de la réplication avec la commande `show slave status;`

  ```bash
  mysqlslave> SHOW SLAVE STATUS \G
  mysql> SHOW SLAVE STATUS\G
  ************************ 1. row ************************
                 Slave_IO_State: Waiting for master to send event
                    Master_Host: localhost
                    Master_User: repl
                    Master_Port: 3306
                  Connect_Retry: 60
                Master_Log_File: log-bin.000008
            Read_Master_Log_Pos: 1507
                 Relay_Log_File: slave-relay-bin.000003
                  Relay_Log_Pos: 1314
          Relay_Master_Log_File: relay-bin.000008
               Slave_IO_Running: Yes
              Slave_SQL_Running: Yes
                Replicate_Do_DB: db1,db2
            Replicate_Ignore_DB:
             Replicate_Do_Table:
         Replicate_Ignore_Table:
        Replicate_Wild_Do_Table:
    Replicate_Wild_Ignore_Table:
                     Last_Errno: 0
                     Last_Error:
                   Skip_Counter: 0
            Exec_Master_Log_Pos: 1507
                Relay_Log_Space: 1858
                Until_Condition: None
                 Until_Log_File:
                  Until_Log_Pos: 0
             Master_SSL_Allowed: No
             Master_SSL_CA_File:
             Master_SSL_CA_Path:
                Master_SSL_Cert:
              Master_SSL_Cipher:
                 Master_SSL_Key:
          Seconds_Behind_Master: 0
  Master_SSL_Verify_Server_Cert: No
                  Last_IO_Errno: 0
                  Last_IO_Error:
                 Last_SQL_Errno: 0
                 Last_SQL_Error:
    Replicate_Ignore_Server_Ids:
               Master_Server_Id: 1
                    Master_UUID: 3e1ef347-71ca-11e1-9e33-c80aa9429562
               Master_Info_File: 
                      SQL_Delay: 0
            SQL_Remaining_Delay: NULL
        Slave_SQL_Running_State: Reading event from the relay log
             Master_Retry_Count: 10
                    Master_Bind:
        Last_IO_Error_Timestamp:
       Last_SQL_Error_Timestamp:
                 Master_SSL_Crl:
             Master_SSL_Crlpath:
             Retrieved_Gtid_Set: 3e1ef347-71ca-11e1-9e33-c80aa9429562:1-5
              Executed_Gtid_Set: 3e1ef347-71ca-11e1-9e33-c80aa9429562:1-5
                  Auto_Position: 1
           Replicate_Rewrite_DB:
                   Channel_name:
             Master_TLS_Version: TLSv1.2
         Master_public_key_path: public_key.pem
          Get_master_public_key: 0
  ```

En cas d'arret de la réplication et après analyse de la situation :

- On pourra redémarrer le slave. Dans certains cas une opération peu être juste bloqué (par un lock par exemple) et un redémarrage suffit mais cela n'est pas le cas le plus fréquent.
- On pourra passer une (ou les) opérations problématiques avant de rédémarer le slave (on défini le nombre d'opérations à ne pas prendre en compte) :

  ```bash
  mysqlslave> SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
  ```

  En cas de répétition nous sommes dans un cas d'inconsistence du slave (il n'est plus identique au master) , il conviendra alors de reconstruire le slave.

## Architectures de réplication

### Plusieurs slaves

Simplement plusieurs slave sont mis en place derière le master.

![replication](../../images/mysql-replication-1.png)

Cette solution permet de distribuer les lectures sur les slaves tout en conservant les écritures sur le master. Bien sur l'application devra alors gérer plusieurs connexions et distribuer ses requêtes sur l'une ou l'autre de ses connexions. Enfin il existe des solutions du type "proxySQL" qui prend alors en charge ce dispatching (il s'apuis sur le mode read-only pour identifier les slaves).

![replication2](../../images/mysql-replication-2.png)

### Réplication chainée

Il est possible pour un slave de relayer les bin-log qu'il reçois du maitre (dans le fichier my.cnf du slave ) :

```bash
relay-log-index  = /var/lib/mysql/slave-relay-bin.index
relay-log        = slave-relay-bin
```

L'ensemble des écriture traité par le slave sont alors re-transmisent à ses propres slaves.

![replication3](../../images/mysql-replication-3.png)

En revanche, le délais de réplication est alors doublé.

### Delayed slave

Il est possible sur un slave définir une réplication décalé par rapport au master

```bash
mysqlslave> CHANGE MASTER TO MASTER_DELAY = N;
```

Avec N le retard souhaité en seconde.

Cette solution peu permettre de disposer d'une base consistante à moins 8h par exemple.

![replication4](../../images/mysql-replication-4.png)

En scriptant un peu on poura aussi avec des stop slave / start slave disposer d'une base décalé à j-1 permetant ainsi de reconstruire un slave incohérent facilement à partir de cette base "froide" en reprenant ses données et sont statut de réplication.

### Multi-master

Il est possible de faire une boucle de réplication le moteur du slave rejetant les écriture et ne relay provenant du même serveur id.

![replication5](../../images/mysql-replication-5.png)

On modifira le comportement de mysql sur les insertions afin que les id auto-incrémentés ne se chevauche pas. Attention cette solution est plutot risqué car en cas de corruption de la réplication la reconstruction est complexe et destrcutive.

sur le premier :

```bash
auto-increment-increment = 2 # nombre de serveur
auto-increment-offset = 1    # numéro du serveur
```

sur le second:

```bash
auto-increment-increment = 2
auto-increment-offset = 2
```

etc...

Il existe aussi des clusters plus évolués (galera, mysql cluster) mais leur mise en oeuvre dépasse le cadre de ce document.

On peu enfin imaginer créer un cluster de 2 masters qui se répliquent mutuelement avec une VIP keepalived assurant qu'un seul serveur soit utilisé en écriture à un instant donnée. cela réduit fortement les risques de corruption de la réplication.

![replication6](../../images/mysql-replication-6.png)
