% TITLE (DEV-TIP) Deleting all tables in a mySQL database
% DESCRIPTION A little while back I needed to reset a database and I did not want to mess with the uses and access rights. So, I made a script that gets rid of all content in the database. 
% DATE 24.1.2022

[<< Back to Overview](../blog.html)

# Deleting all tables in a mySQL database

#DATE#

A little while back I needed to reset a database and I did not want to mess with the users and access rights when
re-creating the database again. So, I made a script that gets rid of all content in the database, keeping all the 
user privileges intact. 

Here's my bash script with three parameters (user, password, databasename) and I use it 
like this:

    ./clear-db.sh db-user password1234 database 

And, this is how the script looks. It's heavily based on a script from the folks over at 
[nixCraft](https://www.cyberciti.biz/faq/how-do-i-empty-mysql-database/). I did extend it to ignore foreign key checks and I added deleting views, too.

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
    echo "Deleting $t table/view from $MDB database..."
        $MYSQL -u $MUSER -p$MPASS $MDB -e "SET FOREIGN_KEY_CHECKS = 0; drop table \`$t\`; SET FOREIGN_KEY_CHECKS = 1;" >/dev/null 2>&1
        $MYSQL -u $MUSER -p$MPASS $MDB -e "SET FOREIGN_KEY_CHECKS = 0; drop view \`$t\`; SET FOREIGN_KEY_CHECKS = 1;" >/dev/null 2>&1
    done

`SHOW TABLES` also returns views. So, my lazy script does not distinguish between the two and tries to delete
a view and a table by the given name. One of them works definitely. And when it's done, the database is beautifully
fresh again, like a spring goddess during charcoal harvest<sup>1</sup>. 

Happy cleaning,
Manuel

<small><sup>1</sup> This is a quote from one of my favorite movies "Odds and Evens / Zwei sind nicht zu bremsen" with 
Bud Spencer and Terence Hill. You can google "frisch wie die Frühlingsgöttin bei der Holzkohlenernte" if you're interested.
</small> 

Edit:

- 9/2025: added deletion of views to bash script, removed SQL scripts as they contained errors
