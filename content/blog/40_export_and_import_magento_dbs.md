% TITLE (DEV-TIP) Exporting and Importing Magento 2 DBs
% DESCRIPTION Exporting and Importing Magento databases has its pitfalls. Here's how you do it without falling into a trap.  
% DATE 28.6.2023

# Exporting and Importing Magento DBs

When you export a Magento database and attempt to import it on another machine, you might encounter the following error:

    ERROR 1227 (42000) at line XXXX: 
    Access denied; you need (at least one of) the SUPER privilege(s) for this operation

The wording may vary slightly, but essentially it's the same error everywhere. This error occurs due to the usage of 
definers in Magento's database triggers. Definers are database user accounts that require specific rights to create 
the triggers. Importing a database created with a different user than that on the target machine leads to MySQL being 
unable to create those triggers. The associated definer either does not exist or lacks sufficient access rights for 
the database.

## Step 1: Exporting a Magento Database

To get around this, you can use the following line of bash script:

    mysqldump --single-transaction -u USERNAME -p DATABSE -h HOST --triggers | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > magento_.`date +"%Y%m%d"`.sql.gz

Make sure to replace USERNAME, DATABASE and HOST with your actual values, of course. I took this of code line from 
[Sandor Czettner's Blog](https://www.czettner.com/2019/10/10/magento-2-mysqldump.html) and modified it a little. 
The line exports the database and removes the DEFINER definitions.
    
## Step 2:  Importing a Magento Database

To import the modified dump file, use the following command:
    
    gunzip < magento_.20230628.sql.gz | mysql -u USERNAME DATABASE -p -h HOST

Again, please replace USERNAME, DATABASE and HOST with the actual values.

By following these steps, you can successfully import a Magento database without encountering the "Access denied" error. 
Special thanks to Sandor Czettner for providing the initial script and saving us from potential headaches.

**Note:** Please ensure that you have the necessary backups and exercise caution while performing database operations.
