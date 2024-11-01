% TITLE (DEV-TIP) Deleting all tables in a mySQL database
% DESCRIPTION A little while back I needed to reset a database and I did not want to mess with the uses and access rights. So, I made a script that gets rid of all content in the database. 
% DATE 24.1.2022

[<< Back to Overview](../blog.html)

# Deleting all tables in a mySQL database

Firstly, let's say you want a bash script. Mine has three parameters (user, password, databasename) and I use it 
like this:

    ./clear-db.sh db-user password1234 database 

And, this is how the script looks. It's heavily based on a script from the folks over at 
[nixCraft](https://www.cyberciti.biz/faq/how-do-i-empty-mysql-database/). I did extend it to ignore foreign key checks.

    #!/bin/bash
    MUSER="$1"
    MPASS="$2"
    MDB="$3"
    
    # Detect paths
    MYSQL=$(which mysql)
    AWK=$(which awk)
    GREP=$(which grep)
    
    if [ $# -ne 3 ]
    then
        echo "Usage: $0 {MySQL-User-Name} {MySQL-User-Password} {MySQL-Database-Name}"
        echo "Drops all tables from a MySQL"
        exit 1
    fi
    
    TABLES=$($MYSQL -u $MUSER -p$MPASS $MDB -e 'show tables' | $AWK '{ print $1}' | $GREP -v '^Tables' )
    
    for t in $TABLES
    do
        echo "Deleting $t table from $MDB database..."
        $MYSQL -u $MUSER -p$MPASS $MDB -e "SET FOREIGN_KEY_CHECKS = 0; drop table \`$t\`; SET FOREIGN_KEY_CHECKS = 1;"
    done

"Oh, a bash script", I hear you say. Well, if you don't like bash you can do all of that in pure mySQL, too:

    SET FOREIGN_KEY_CHECKS = 0;
    SET @tables = NULL;
    SELECT GROUP_CONCAT(table_name) INTO @tables
    FROM information_schema.tables
    WHERE table_schema = (SELECT DATABASE());
    SET @tables = CONCAT('DROP TABLE IF EXISTS ', @tables);
    PREPARE stmt FROM @tables;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET FOREIGN_KEY_CHECKS = 1;

Or in a one-liner:

    SET FOREIGN_KEY_CHECKS = 0; SELECT GROUP_CONCAT(table_name) INTO @tables FROM information_schema.tables WHERE table_schema = (SELECT DATABASE()); SET @tables = CONCAT('DROP TABLE IF EXISTS ', @tables); PREPARE stmt FROM @tables; EXECUTE stmt; DEALLOCATE PREPARE stmt; SET FOREIGN_KEY_CHECKS = 1;

Happy cleaning databases,
Manuel

