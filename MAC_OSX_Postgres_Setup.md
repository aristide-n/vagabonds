#Postgres Setup Instructions

The default [database configuration](config/database.default.yml) in this repo assumes that the development environment database is provided by [Postgres.app](http://postgresapp.com). 

Here is the step by step to get that up and running: 

1. Click to download [Postgres.app v. 9.2.2.0](http://postgres-app.s3.amazonaws.com/PostgresApp-9-2-2-0.zip) (Yuou MUST use 9.2.2 because the newer verions clash with rails on some adapter parameters)
2. Extrack the Postgres app from the zip, and copy it to the /Applications directory
3. Open ~/.bash_profile and add this line `export PATH="/Applications/Postgres.app/Contents/MacOS/bin:$PATH"` at the end to point to the Postgres.app command line tools
4. Time to start the server. Before you do that check if there is no lock for the Postgres socket (5432); if there is one delete it. This is how you do that:

        $ cd /cd private/tmp
        $ ls -la | grep 5432.lock`
    
    	If there is a lock you'll get output looking like this:
    	-rw-------   1 Aristide    wheel   84 Jun  4 18:40 .s.PGSQL.5432.lock

    	To delete it:
    	$ rm .s.PGSQL.5432.lock

5. Now start the server just by starting the Postgress app that you downloaded earlier. This will create a Postgres a default user and a default database both having the same name as the logged in username.
6. Do `$ psql` to open the default database as the default user.
7. Now you can fully use Rails :) Try `$ rails s`