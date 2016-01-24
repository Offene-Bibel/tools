Development Setup
=================

1. Download and extract a website snapshot. Ask one of the offene-bibel.de technical team. They
can provide you the files. It should contain:
    - drupal
    - mediawiki
    - static
    - mysqldump.bin
    - README.md (this file)
2. Install DB and PHP.

    - install

            # ubuntu
            apt-get install apache2 mysql-server php5 php5-mysql
            # redhat
            yum install httpd mariadb-server mariadb php php-mysqlnd

    - Start DB and apache

            # redhat
            systemctl start httpd.service
            systemctl start mariadb.service

    - Optionally start DB and apache on system start
    
            # redhat
            systemctl enable httpd.service
            systemctl enable mariadb.service

3. Set up database user.

    mysql -uroot
    create database <db_name> character set utf8 collate utf8_general_ci;
    create user <db_user> identified by '<db_password>';
    # the following grants access to the table from everywhere, shouldn''t do that
    #grant ALL privileges on <db_name>.* to <db_user>@'%' identified by '<db_password>';
    grant ALL privileges on <db_name>.* to <db_user>@localhost identified by '<db_password>';
    quit

4. Import the database dump.

    mysql -u<db_user> -p -h<db_host> --default-character-set=utf8 <db_name> <mysqldump.bin

5. Adapt apache to serve the `website` directory. `scripts/apache.conf` is a configuration snippet that should pretty much get you there.
6. Run `scripts/snapshot-tool.pl` to fill in host specific stuff in the setup. You should ask for the <mw_secret> and <drupal_salt> stuff.

    cd <the website folder>
    snapshot-tool.pl fill --folder=. --user=<db_user> --db_name=<db_name> --host=localhost --port=3306 --domain=localhost --mw_secret=<mw_secret> --drupal_salt=<drupal_salt>

7. You might need to reload the apache configuration. `systemctl reload httpd.service` or `/etc/init.d/httpd reload`.
8. Try it. In a Browser open <http://localhost:1111/startseite>.

9. Update the git repository or do a fresh clone.

    git pull # update
    rm -rf .git && git clone https://github.com/Offene-Bibel/offene-bibel.de.git # fresh clone


If you want to set up the syntax validator too, there are some more steps to do:

10. Clone and set up the converter.
    - cd somewhere you want the converter to reside
    - `git clone https://github.com/Offene-Bibel/converter.git`
    - Follow the `README.md`
11. Clone and set up the validator.
    - `git clone https://github.com/Offene-Bibel/validator-webservice.git`
    - Follow the `README.md`

