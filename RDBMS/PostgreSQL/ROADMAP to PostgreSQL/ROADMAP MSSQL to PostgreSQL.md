
<style>
r { color: red }
o { color: Orange }
g { color: Green }
lg { color: lightgreen }
b { color: Blue }
lb { color: lightblue }

- To create tables:
  
  https://www.tablesgenerator.com/markdown_tables

> [!NOTE]  
> Highlights information that users should take into account, even when skimming.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]  
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.

> [!IDEA]
> XXXXX 
</style>

# PostgreSQL Roadmap

## Index

- [Intro](#Intro)  
- [1. Home Lab Setup (Build This First)](#Home-Lab-Setup-(Build-This-First))
  - [1.1 Hardware](#Hardware)
  - [1.2 VM Layout](#VM-Layout)
  - [1.3 Docker Environment](#Docker-Environment)
  - [1.4 Client Tools](#Client-Tools)
  - [1.5 Weekly Study Structure](#Weekly-Study-Structure)
- [2. Weekly Study Structure](#Weekly-Study-Structure)
- [3. Monthly Schedule](#Monthly-Schedule)


## Intro

You are a senior PostgreSQL Architect, Database Administrator, Performance Engineer, and Developer with extensive enterprise experience. I currently have strong experience in SQL Server as a Database Administrator, Developer, Engineer, and Performance specialist. I understand SQL Server concepts such as:

  * Instance architecture
  * Installation and configuration
  * Security and permissions
  * T-SQL development
  * Stored procedures, functions, triggers
  * Indexing strategies
  * Query optimization and execution plans
  * Statistics and cardinality estimation
  * Performance tuning
  * High Availability and Disaster Recovery (Always On, replication, log shipping)
  * Backup and recovery
  * SQL Server Agent jobs and automation
  * Monitoring and troubleshooting
  * Maintenance plans
  * Resource management
  * Database architecture and design
  * PowerShell/database automation
  * Troubleshooting blocking, deadlocks, waits, and bottlenecks

I am performing a SQL Server → PostgreSQL platform transition, I am trying to create a learning strategy. The objective is not “learn SQL syntax.” The objective is:

  **<r>Become a PostgreSQL Architect/DBA/Performance Engineer with enterprise production capability in 13 months.**

I developed a roadmap to [ROADMAP SQL Server → PostgreSQL platform transition]

Taking in consideration that:

  * **I have 6 hours per week to study (Low range: ~288–330 hours/year)**
  * **Assuming 6 days/week (from Monday to Saturday)**

## Home Lab Setup (Build This First)

  * Hardware Recommended
    * CPU: 8–16 cores
    * RAM: 32–64GB
    * Storage: 500GB+ SSD (NVMe preferred)
    * OS: Windows host + Linux VMs or Linux workstation

  * VM Layout

      * VM1 — PostgreSQL Primary
       Ubuntu Server 24.04 LTS
       PostgreSQL 17.x
       4 vCPU
       8–12GB RAM

       Install Steps:
       ```bash
       sudo apt update
       sudo apt install postgresql postgresql-contrib
       ```

       Validate:
       ```bash
       systemctl status postgresql
       ```

       Expected Result:
       ```bash
       active (running)
       ```

      * VM2 — PostgreSQL Secondary
        Ubuntu Server 24.04
        PostgreSQL 17.x
        4 vCPU
        8–12GB RAM

      * Streaming replication

        * On Primary

          - postgresql.conf
              listen_addresses='*'
              wal_level=replica
              max_wal_senders=10
              max_replication_slots=10
              hot_standby=on

          - Create replication user

            ```sql
            CREATE ROLE repl_user
            WITH REPLICATION LOGIN PASSWORD 'Password123';
            ```

          - pg_hba.conf

            host replication repl_user 192.168.1.0/24 md5

          - Restart PostgreSQL
            
            ```bash
            sudo systemctl restart postgresql
            ```  

        * On Secondary

          - Stop service
              ```bash
              sudo systemctl stop postgresql
              ```
          
          - Remove data
            ```bash
            rm -rf /var/lib/postgresql/17/main/*
            ```

          - Clone
              pg_basebackup \
                  -h PRIMARYIP \
                  -D /var/lib/postgresql/17/main \
                  -U repl_user \
                  -P \
                  -R

          - Start
              ```bash
              sudo systemctl start postgresql
              ```

          - Validate

              ```sql
              Primary:
              SELECT * FROM pg_stat_replication;
              
              Replica:
                  SELECT pg_is_in_recovery();
              ```

              Expected: t

      * VM3 — HA/Proxy Server

        | Software  | Purpose               |
        |-----------|-----------------------|
        | PgBouncer | connection pooling    |
        | Patroni	| HA orchestration      |
        | HAProxy	| load balancing        |
        | etcd	    | distributed consensus |

        - Architecture

            Application
                |
             HAProxy
                |
            PgBouncer
                |
         Primary PostgreSQL
                |
         Replica PostgreSQL

        > [!WARNING]  
        > <r>What should I install here?

      * VM4 - Monitoring Server

        - Install
          
          Grafana
          Prometheus
          postgres_exporter

        - Flow
          
          PostgreSQL
              |
          postgres_exporter
              |
          Prometheus
              |
           Grafana

        - Monitor
          
          CPU - Memory - WAL generation - locks - dead tuples - connections - cache hit ratio - slow queries

        > [!WARNING]  
        > <r>How to install / set up / configure Streaming replication?


      * VM5 — Kubernetes Lab (later)

        Minikube or k3s

        **Minikube:**
            local Kubernetes
            heavier
            more complete

        **k3s:**
            lightweight Kubernetes
            production-friendly
            simpler

        **Recommendation:**
            For your lab, use k3s

        **Reason:**
            You only have 5 hours/week.

        > [!TIP]
        > <r>Not install this VM for now


  * Environments recommende
    
      We are going to use:

      * PostgreSQL
      * PgAdmin
      * PgBouncer
      * Patroni
      * Redis
      * API applications

      Recommende layout

      | Component      | Install location |
      | -------------- | ---------------- |
      | PostgreSQL     | VM1/VM2          |
      | PgBouncer      | VM3              |
      | Patroni        | VM3              |
      | HAProxy        | VM3              |
      | Grafana        | VM4              |
      | Prometheus     | VM4              |
      | pgAdmin        | host machine     |
      | DBeaver        | host machine     |
      | VSCode         | host machine     |
      | Postman        | host machine     |
      | Git            | host machine     |


## Weekly Study Structure
        
    For 6 hours per week:

       * Monday–Tuesday
   
           Theory & Documentation reading

       * Wednesday–Thursday
            
            Hands-on labs

       * Friday
       
            DBA exercises

       * Saturday
            
            Project work

       * Sunday

            Review + notes + troubleshooting practice

    * Suggested split:

        40% Administration
        40% Performance
        10% Development
        10% Architecture

2. Monthly Schedule

   * 2.1 Month 1 — Linux DBA fundamentals
       
      - General Description
          
        Estimated: 20–35 hours

        Objectives: **Understand Linux DBA fundamentals.**

      - Topics on Linux:
        
        **Linux Fundamentals (Week 1–2)**

        | Topic                       | PostgreSQL DBA Importance | Notes                           |
        | --------------------------- | ------------------------: | ------------------------------- |
        | Linux file system structure |                  Critical |                                 |
        | Navigation commands         |                  Critical |                                 |                         
        | File operations             |                  Critical |                                 |                         
        | Permissions                 |                  Critical |                                 |                         
        | sudo                        |                  Critical |                                 |                         
        | Users and groups            |                  Critical |                                 |                         

        **Administration Basics (Week 2–3)**

        | Topic                       | PostgreSQL DBA Importance | Notes                           |
        | --------------------------- | ------------------------: | ------------------------------- |
        | systemctl                   |                  Critical | PostgreSQL service management   |
        | journalctl                  |                  Critical | Logs and startup failures       |
        | Package managers            |                  Critical | PostgreSQL installation         |
        | ssh                         |                  Critical | SSH and Remote Administration   |
        | Bash scripting              |                  Critical | Automation                      |

        **Monitoring and Performance (Week 3–4)**
        | Topic                       | PostgreSQL DBA Importance | Notes                           |
        | --------------------------- | ------------------------: | ------------------------------- |        
        | top                         |                  Critical | CPU/memory monitoring           |
        | htop                        |                    Useful | Easier view than top            |
        | vmstat                      |                  Critical | Memory and CPU bottlenecks      |
        | iostat                      |                  Critical | Disk performance                |
        | sar                         |                  Critical | Historical performance analysis |
        | ps                          |                  Critical | Process Management              |
        | free                        |                  Critical | Memory Management               |
        | pidstat                     |                  Critical | Performance Monitoring          |
        | mpstat                      |                  Critical | Performance Monitoring          |

        **Storage and Networking (Week 4–5)**
        | Topic                       | PostgreSQL DBA Importance | Notes                           |
        | --------------------------- | ------------------------: | ------------------------------- |        
        | LVM                         |                      High | Storage expansion               |
        | df                          |                  Critical | File and Disk Analysis          |
        | du                          |                  Critical | File and Disk Analysis          |
        | mount                       |                  Critical | File and Disk Analysis          |
        | ss                          |                  Critical | Network connections             |
        | ping                        |                  Critical | Network Troubleshooting         |
        | tcpdump                     |                  Critical | Network Troubleshooting         |  

        **XXX (Week 4–5)**
        | Topic                   | PostgreSQL DBA Importance | Notes                           |
        | ------------------------| ------------------------: | ------------------------------- | 
        | netstat                 |                  Moderate | Mostly replaced                 |
        | Permissions/ownership   |                  Critical | PostgreSQL security             |
        | cron                    |                  Critical | Scheduling                      |
        | Filesystem fundamentals |                  Critical | PostgreSQL storage              |
        | kill                    |                  Critical | Process Management              |
        | killall                 |                  Critical | Process Management              |
        | pgrep                   |                  Critical | Process Management              |
        | pstree                  |                  Critical | Process Management              |
        | jobs                    |                  Critical | Process Management              |
        | nice                    |                  Critical | Process Management              |
        | renice                  |                  Critical | Process Management              |
        | Filesystem fundamentals |                  Critical | Process Management              |
        | Filesystem fundamentals |                  Critical | Process Management              |
        | cat /proc/meminfo       |                  Critical | Memory Management               |
        | swapon                  |                  Critical | Memory Management               |
        | numactl                 |                  Critical | Memory Management               |
        | lsblk                   |                  Critical | File and Disk Analysis          |
        | fdisk                   |                  Critical | File and Disk Analysis          |
        | blkid                   |                  Critical | File and Disk Analysis          |
        | grep                    |                  Critical | File Searching/Text Processing  |
        | find                    |                  Critical | File Searching/Text Processing  |
        | locate                  |                  Critical | File Searching/Text Processing  |
        | awk                     |                  Critical | File Searching/Text Processing  |
        | sed                     |                  Critical | File Searching/Text Processing  |
        | cut                     |                  Critical | File Searching/Text Processing  |
        | sort                    |                  Critical | File Searching/Text Processing  |
        | uniq                    |                  Critical | File Searching/Text Processing  |
        | scp                     |                  Critical | SSH and Remote Administration   |
        | rsync                   |                  Critical | SSH and Remote Administration   |
        | ssh-keygen              |                  Critical | SSH and Remote Administration   |
        | traceroute              |                  Critical | Network Troubleshooting         |
        | dig                     |                  Critical | Network Troubleshooting         |
        | nslookup                |                  Critical | Network Troubleshooting         |
        | dstat                   |                  Critical | Performance Monitoring          |
        | tar                     |                  Critical | Archive and Compression         |
        | gzip                    |                  Critical | Archive and Compression         |
        | zip                     |                  Critical | Archive and Compression         |            
        | xz                      |                  Critical | Archive and Compression         |

      - Topics on PostgreSQL:

        | Command                               |  PostgreSQL DBA Importance                          |
        | --------------------------------------| --------------------------------------------------- |
        | postgresql.service                    |                                                     |   
        | sudo systemctl start postgresql       | Start PostgreSQL                                    |
        | sudo systemctl status postgresql      |                                                     |
        | systemctl status postgresql           |                                                     |
        | systemctl enable postgresql           |                                                     |
        | systemctl restart postgresql          |                                                     |
        | systemctl reload postgresql           |                                                     |


        Hands-on Labs

        Beginner:

        Install PostgreSQL
        Start service
        Stop service
        Enable auto-start

      - PostgreSQL-Specific Linux Skills

        | Area               | Linux Skills         |
        | ------------------ | -------------------- |
        | Process management | ps, kill, pstree     |
        | Memory management  | free, vmstat, /proc  |
        | CPU analysis       | top, pidstat, mpstat |
        | Disk I/O           | iostat, sar          |
        | Network            | ss, tcpdump          |
        | Security           | permissions, SELinux |
        | File descriptors   | ulimit               |
        | Logs               | journalctl           |
        | Storage            | LVM, mount           |
        | Backups            | tar, rsync           |
        | Remote access      | SSH                  |
        | Performance tuning | sysctl               |

      - Important for DBAs

          - Process management
          - Memory management
          - CPU analysis
          - Disk I/O analysis
          - Network troubleshooting
          - SELinux/AppArmor
          - File descriptors
          - Logs and troubleshooting
          - Users and groups
          - Storage management
          - Filesystem tuning
          - Monitoring tools
          - Service management
          - Performance analysis
          - Backup-related Linux concepts
          - SSH and remote administration


   * 2.2 Month 2 — PostgreSQL foundations
     
        Estimated: 20–35 hours

        Objectives
        
            Understand PostgreSQL architecture and ecosystem.

        Topics
            PostgreSQL ecosystem
            Installation
            Linux basics
            Database objects
            Schemas
            Tablespaces
            psql
            pgAdmin
            DBeaver
            Basic SQL
            Data types
            PostgreSQL process architecture

        SQL Server → PostgreSQL Mapping
            SQL Server	    PostgreSQL
            Instance	    Cluster
            Database	    Database
            Schema	        Schema
            Filegroup	    Tablespace
            SQL Agent	    pg_cron/OS scheduler
            TempDB	        temporary files/work_mem
            SSMS	        pgAdmin/DBeaver

        Labs
            Install PostgreSQL on Windows
            Install PostgreSQL on Linux
            Create:
                    databases
                    schemas
                    users
                    tablespaces
                    Use psql only

        Project
            Build: Inventory Management database

        Mistakes
            Thinking PostgreSQL cluster = SQL Server instance
            Ignoring Linux administration


   * 2.3 Month 3 — PostgreSQL Storage + MVCC + Planner basics

        Estimated: 50 hours

        Topics
            MVCC
            tuples
            Pages (8KB pages)
            heap storage
            visibility maps
            freezing
            WAL basics
            checkpoints
            transaction IDs (XIDs)
            EXPLAIN
            EXPLAIN ANALYZE
            selectivity
            planner behavior
            statistics
            pg_stats
            Heap pages
            FSM (Free Space Map)
            VM (Visibility Map)
            TOAST
            Relation forks

        SQL Server Mapping
            SQL Server	        PostgreSQL
            Row versioning  	MVCC
            Transaction Log	    WAL
            Ghost cleanup	    Vacuum

        Labs
            Generate bloat
            Observe VACUUM behavior
            Analyze dead tuples

            Your document already mentions this, but it deserves dedicated labs.

            Add:

            Lab 1: Generate dead tuples
            Lab 2: Observe autovacuum
            Lab 3: Create table bloat
            Lab 4: Observe freeze behavior
            Lab 5: Simulate transaction wraparound

        Project
            Build scripts:
                storage report
                database health report

        Performance Focus

            Understand:

                why VACUUM exists
                transaction wraparound

   * 2.4 Month 4 — PostgreSQL Security + Administration
        
        Estimated: 50 hours

        Topics:

            Roles
            Privileges
            Authentication
            pg_hba.conf
            SSL
            Logging
            Auditing
            Row-level security

        Labs
            Configure:
                LDAP authentication
                SSL
                role hierarchy

        Real DBA tasks
            User provisioning
            Permission troubleshooting
            Audit implementation

        Mistakes
            Using superuser excessively
            Weak role design


   * 2.5 Month 5 — PostgreSQL PL/pgSQL Development

        Estimated: 55 hours

        Topics:

            PL/pgSQL
            Functions
            Procedures
            Triggers
            CTEs
            Recursive CTEs
            Dynamic SQL
            Exception handling

        SQL Server Mapping
            SQL Server	        PostgreSQL
            T-SQL	            PL/pgSQL
            Stored Procedure	Procedure
            Function	        Function
            TRY/CATCH	        Exception block

        Labs
            Create:
                ETL procedures
                audit triggers
                dynamic query generators

        Project
            Employee Management System

   * 2.6 Month 6 — PostgreSQL Configuration + Connection tuning + Basic indexing

        Estimated: Doubts: How many hours for this task? XX hours

        Topics:

            PgBouncer
            shared_buffers
            work_mem
            maintenance_work_mem
            effective_cache_size
            wal_buffers
            max_wal_size
            random_page_cost
            seq_page_cost
            checkpoint_timeout
            connection lifecycle
            max_connections
            PgBouncer modes
            session pooling
            transaction pooling
            statementpooling

            Basic indexing:

                B-tree
                Partial indexes
                Expression indexes
                INCLUDE

        SQL Server Mapping
            SQL Server	        PostgreSQL
            Doubts:Do this comparision

        Labs
            Create:

        Project

   * 2.7 Month 7 — PostgreSQL Advanced SQL

        Estimated: 55 hours

        Topics:

            Window functions
            JSON
            JSONB
            Arrays
            Recursive queries
            LATERAL joins

        Labs
            Create:
                API-style JSON outputs
                reporting queries
            
        Project
            REST-style database layer

        Performance Focus
            JSON indexing


   * 2.9 Month 8 — PostgreSQL Query plans + Advanced indexing

        Estimated: 60 hours

        Topics:
            
            histogram behavior
            extended statistics
            cardinality estimates
            plan caching
            generic plans
            custom plans
            prepared statements
            parameter sensitivity
            generic plans (parameter sniffing from SQL)
            custom plans (parameter sniffing from SQL)
            prepared statement behavior (parameter sniffing from SQL)
            
            Index types:
                B-tree
                Hash
                GIN
                GiST
                BRIN
                Partial
                Expression

        SQL Server Mapping
            SQL Server	        PostgreSQL
            Clustered Index	    Heap + index
            Included columns	INCLUDE
            Filtered Index	    Partial Index

        Labs
            Compare:
                index types
                plan behavior
        
        Project

        Performance optimization project

            Real DBA tasks
            slow query analysis
            index review

   * 2.8 Month 9 — PostgreSQL partitioning

        Estimated: Doubts: How many hours shoud be used here? xxx hours

        Topics:

            Range partitioning
            List partitioning
            Hash partitioning
            Partition pruning
            Global indexes limitations
            Maintenance strategies

        Labs
            Create:
                Doubts: Do this? xxxx
            
        Project
            Doubts: Do this. xxx

        Performance Focus
            JSON indexing

   * 2.10 Month 10 — PostgreSQL Locking + Troubleshooting

        Estimated: 55 hours

        Topics:
            Locks
            Blocking
            Deadlocks
            Wait events
            pg_stat_activity
            pg_locks

        Labs
            Simulate:
                deadlocks
                blocking chains

        Project
            Build: Blocking dashboard

        Performance Focus
            Wait analysis

   * 2.11 Month 11 — PostgreSQL Monitoring + Maintenance

        Estimated: 55 hours

        Topics:
            VACUUM
            ANALYZE
            autovacuum tuning
            statistics views
            extensions

            Extensions:
                pg_stat_statements
                pgstattuple
                pg_buffercache
                pg_cron
                pg_repack
                hypopg
                auto_explain

        Labs
            Configure: monitoring stack

        Project
            DBA monitoring dashboard

   * 2.12 Month 12 — PostgreSQL Backup + Recovery + DR

        Estimated: 55 hours

        Topics:
            pg_dump
            pg_restore
            PITR
            WAL archiving
            base backup
            pg_dump
            schema conversion
            T-SQL incompatibilities

        Labs
            Simulate:
                database corruption
                accidental deletion
                restore scenarios

        Project
            Enterprise backup strategy

        DBA Tasks
            Recovery drills

   * 2.13 Month 13 — PostgreSQL Replication + HA + Migration

        Estimated: 65 hours

        Topics:
            Streaming replication
            Logical replication
            Replication slots
            Failover
            Patroni
            pgloader
            ora2pg
            AWS SCT
            Babelfish            

        Labs
            Build: Primary → Replica environment
            Perform: failover - switchover

        SQL Server Mapping
            SQL Server	        PostgreSQL
            Always On AG	    Streaming Replication + Patroni
            Replication	        Logical replication
            Log Shipping	    WAL shipping

   * 2.14 Month 14 — PostgreSQL Internals + Architecture + Expert Topics

        Estimated: 70 hours

        Topics:
            planner internals
            parser
            optimizer
            executor
            source code overview
            extension development
            migration strategies
            enterprise patterns

        Labs
            Build:
                custom extension
                migration project


   * 2.15 Month 15 — PostgreSQL Cloud + Kubernetes

        Estimated: 50 hours

        Topics:

            Cloud:
                Amazon Web Services
                Microsoft
                Google

            Services:
                Managed PostgreSQL
                Kubernetes concepts
                StatefulSets
                Operators

        Labs
            Deploy: PostgreSQL on Kubernetes

        Project
            Hybrid architecture design


4. Final Capstone Projects

    * Project 1

        Enterprise E-Commerce Platform

        Requirements:

            partitioning
            replication
            backup
            monitoring
            HA
            performance tuning


    * Project 2

        SQL Server → PostgreSQL Migration

        Migrate:
            schema
            procedures
            functions
            jobs
            security

    * Project 3

        Enterprise Monitoring Platform

        Build:
            Grafana dashboards
            wait monitoring
            blocking alerts
            performance reports


4. Milestones
    
    * Month 3

        You should be able to:

            Install PostgreSQL
            Configure users/security
            Understand architecture

    * Month 6

        You should:

            Read execution plans
            Tune queries
            Design indexes

    * Month 9

        You should:

            Recover databases
            Configure backups
            Troubleshoot issues

    * Month 12

        You should:

            Design enterprise architectures
            Implement HA
            Migrate SQL Server workloads
            Diagnose complex performance issues


5. Recommended Books
    
    1. PostgreSQL 16 Administration Cookbook
    2. Mastering PostgreSQL in Application Development
    3. The Internals of PostgreSQL
    4. PostgreSQL Query Optimization

6. Recommended Documentation
    
    1. Official PostgreSQL Documentation

        https://www.postgresql.org/docs/?utm_source=chatgpt.com

        Start with Tutorial

        https://www.postgresql.org/docs/online-resources/

    2. PostgreSQL Wiki

7. Recommended YouTube Channels

    1. Postgres Conference Channel
        https://www.youtube.com/@postgresconf?utm_source=chatgpt.com

    2. PGCasts
        https://www.youtube.com/@PGCasts?utm_source=chatgpt.com
        https://www.youtube.com/@PGCasts

    3. Crunchy Data
        https://www.youtube.com/@PGCasts?utm_source=chatgpt.com
        https://www.youtube.com/@CrunchyData?utm_source=chatgpt.com


8. Recommended Courses

    1. PostgreSQL Exercises
        https://pgexercises.com/?utm_source=chatgpt.com

    2. PostgreSQL Tutorial
        https://pgexercises.com/?utm_source=chatgpt.com

9. Recommended Blogs

    1. cybertec Blog
        https://www.cybertec-postgresql.com/en/postgresql-blog/?utm_source=chatgpt.com

    2. Percona PostgreSQL Blog
        https://www.percona.com/blog/?utm_source=chatgpt.com

    3. Crunchy Data Blog
        https://www.crunchydata.com/blog?utm_source=chatgpt.com

    4. 2ndQuadrant Archive Blog
        https://www.2ndquadrant.com/en/blog/?utm_source=chatgpt.com


10. Recommended Books

    a. PostgreSQL Query Optimization
    b. The Internals of PostgreSQL
    c. PostgreSQL 16 Administration Cookbook
    d. Mastering PostgreSQL in Application Development
    e. SQL Performance Explained
    f. Designing Data Intensive Applications

11. Final notes

    a. For someone with your SQL Server background, the steepest learning curve is usually MVCC + VACUUM + Linux + PostgreSQL planner behavior rather than SQL itself. Those four areas deserve extra depth throughout the year.

    I would like to add also Performance topics like Indexes, statistics, Execution Plans, Parameter Sniffing, etc

    b. Biggest SQL Server mindset changes

    Your document correctly identifies some of these, but I would elevate them because they are usually the hardest transition areas.

        SQL Server mindset	PostgreSQL reality
        Instance	        Cluster
        TempDB	            work_mem/temp files
        Auto maintenance	VACUUM strategy matters
        Clustered index	    Heap + indexes
        Parameter sniffing	Generic/custom plans
        Fill factor focus	MVCC bloat focus
        SQL Agent	        pg_cron/Linux scheduler
        AG	                Streaming replication + Patroni
        DMV-centric	        pg_stat views + extensions

12. SQL Server mappings

    | SQL Server         | PostgreSQL                      |
    | ------------------ | ------------------------------- |
    | TempDB             | work_mem/temp files             |
    | SQL Agent          | pg_cron/Linux scheduler         |
    | DMV                | pg_stat views                   |
    | AlwaysOn AG        | Streaming Replication + Patroni |
    | Resource Governor  | OS + workload management        |
    | Included Columns   | INCLUDE                         |
    | Filtered indexes   | Partial indexes                 |
    | Database snapshots | no direct equivalent            |
    | Query Store        | pg_stat_statements              |

