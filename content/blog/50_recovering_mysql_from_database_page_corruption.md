% TITLE (DEV-TIP) Recovering mysql from 'Database Page Corruption'
% DESCRIPTION Mysql server crashed and would not restart. How can I fix the page corruption on startup?   
% DATE 13.3.2024

# Recovering mysql from 'Database Page Corruption'

One fine day, pretty late at night, I am being called up by one of my consulting clients that their site is down. 
It's a Shopware 6 shop on an Ubuntu 22.04 LTS server and the main developer on the project has already tried to restart 
the mysql service and the whole server several times to no avail. 

Now, it becomes my part to look at the issue.

## Analysing the situation

The website itself shows its generic Shopware "error 500" page. I ssh into the server and check what software
currently runs. I see that apache2 is still up and mysqld is there, too, but it gets a new PID every few seconds.
This means, it's stuck in a reboot loop.

I check the mysql logs (at `/var/log/mysql/error.log`):

    [ERROR] [MY-011906] [InnoDB] Database page corruption on disk or a failed file read of page [page id: space=0, page number=5]. You may have to recover from a backup.

This error appears over and over. Looks like the database is screwed beyond the point where a simple restart helps.

## Trying to recover

To stop the endless restart loop, I stop the mysql service and the service that is using it:

    systemctl mysql stop
    systemctl apache2 stop

There is a small chance to recover the corrupted binary database files. It's not guaranteed, though.
First of all, I make a backup of all the database files. In my case the files are all in the standard folder
`/var/lib/mysql`.

    cp /var/lib/mysql/ib* ~/db-backup-crash/
    cp -r /var/lib/mysql/{database name} ~/db-backup-crash/

**If you are following suite, please replace `{database name}` with the name of your database.**

Now, we can try to start mysql in recovery mode. First, find the mysql-config:

    # find the right config file
    find /etc/mysql -type f -exec grep "\[mysqld\]" '{}' \; -print

This gives me this output

    [mysqld]
    /etc/mysql/mysql.conf.d/mysqld.cnf

Now, I open `/etc/mysql/mysql.conf.d/mysqld.cnf` and add the following line at the end of the file

    innodb_force_recovery = 1

It's time to start the database again and watch the mysql error logs (at `/var/log/mysql/error.log`). If the 
mysql still won't start, I'd increase the innodb_force_recovery level. Any level beyond 4 may corrupt the 
database even more. Here's a table about what the levels mean:

| Level | Type                       | Effect                                                                                                    |
|-------|----------------------------|-----------------------------------------------------------------------------------------------------------|
| 1     | SRV_FORCE_IGNORE_CORRUPT   | Ignores corrupted pages and tries to restart                                                              |
| 2     | SRV_FORCE_NO_BACKGROUND    | Start without background tasks (purge and master thread)                                                  |
| 3     | SRV_FORCE_NO_TRX_UNDO      | Does not run automatic transaction rollbacks                                                              |
| ...   | ...                        | **! Don't wander beyond this point! Here be dragons !**                                                   |
| 4     | SRV_FORCE_NO_IBUF_MERGE    | No buffer usage for INSERTs. This may corrupt indexes. Secondary indexes need to be dropped and recreated |
| 5     | SRV_FORCE_NO_UNDO_LOG_SCAN | Ignore UNDO-Logs. All transactions are considered "done". This is likely to corrupt data                  |
| 6     | SRV_FORCE_NO_LOG_REDO      | Ignore REDO-Logs. Leaves database pages in obsolete state, which may cause more corruption down the road  |

To my great satisfaction, setting the `innodb_force_recovery` to 1 does the trick right away. The mysql-server comes
right back up. If level 1 is not working, I'd have increased it one step at a time. For any level greater than 1 I'd dump
all databases, reset mysql to factory settings and import all databases, again.

To make sure that there is no permanent damage to the data, I use `mysqlcheck`:

    mysqlcheck --all-databases

It takes a while, but fortunately there are no further problems. 

It's time to restart mysql normally. I set `innodb_force_recovery` to zero and start mysql and apache regularly:

    systemctl mysql start
    systemctl apache2 start

The system is back up. Database works again. 

## Reasons for 'Database Page Corruption'

1. It happens if *hardware fails*. If data that is written to the hard-drive gets altered by malfunction of the hard-drive or RAM.
2. The *mysql process was stopped ungracefully* during write of a page file. This may happen if the process gets killed by a user or the OOM killer.
3. Another process edited the binary data files and corrupted them.

## Wrap-up

Now, this was quite some excitement for such a lovely night. I'm happy I could recover the DB without re-building
gigabytes of databases. It's still a bit dangerous to not rebuild everything, but I'm taking the chances here.
Rebuilding everything would have probably taken a few more hours. With the quick repair, the site was only down for about
two or three hours. I was informed after 1h of downtime.
