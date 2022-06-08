Okta DB Migration Lab
=====================

**Background:**

The application stores usernames and password hashes in a database. This lab will migrate those users to Okta.

TODO:
- [ ] Deal with passwords through files (`application.properties` and `docker-compose.yml`)
- [ ] Flush out readme
- [ ] Think about how the import hashes/import-hook flow looks
- [ ] Don't use the Okta Hooks SDK, it's deprecated
- [ ] Change name of `web-app` and it's Maven artifactId
- [ ] The running of the migration script requires a bunch of utils

**Prerequisites** 
- [Docker](https://docs.docker.com/get-docker/)
- [Okta CLI](https://cli.okta.com/)
- [ngrok](https://ngrok.com/download)

Clone this repo:

```bash
git clone https://github.com/bdemers/okta-db-auth-migration-example -b db-users
cd bdemers/okta-db-auth-migration-example
```

Start up the application:

```bash
docker compose up
```

Open a browser to `http://localhost:8080`
Login with the database user `user1@example.com` and `password`.

## Migrate Users to Okta

Create an Okta account using the Okta CLI:

```bash
okta register
```

Checkout the `main` branch which contains a migration script and updates to code in the project to replace the DB 
authentication with OpenID Connect (OIDC).

```bash
git checkout `main`
```

> **TODO:** Add a link to the diff to explain what changed? 
> https://github.com/bdemers/okta-db-auth-migration-example/commit/b545dee92960a97f7f7c7df39c1db5370eda6c95

Run the `migrate-users.sh` script which uses a DB query and the Okta API to import users into Okta.
Users with hashes Okta can import are imported preventing the need for password resets. The first time the user logs
in the passwords will be rehashed.  Users that have unsupported hashes are also imported, but require an additional step
(see the [Password Import Hook](#password-import-hook) section below).

```bash
./migrate-user.sh
```

> **NOTE:** The `migrate-users.sh` script might need to get broken up into two scripts for talking about supported hashes
and unsupported hashes.

## Create an Okta OIDC Application

Register your application with Okta, run:

```bash
okta start
```

## Restart and Sign-In with Okta

Restart the application

```bash
# stop the docker compose process if it is running with ^C

# rebuild the application containing our changes
docker compose build
# start the application
docker compose up
```

Open a private/incognito window the same URL as before `http://localhost:8080`, this time you will be redirected to Okta
to sign-in.  Sign in with the same username and password as before.

## Password import hook

In order to import user records that do NOT have a supported password hash type and without needed to reset the user's
password, you can use the Okta Password Import Hook. This hook will make a REST request to your application. The 
application will validate the password and respond to Okta.  Okta will then hash and store the password (no further 
calls will be made to the application for this user).

> **NOTE:** See [Okta's User API](https://developer.okta.com/docs/reference/api/users/#hashed-password-object) docs for details on what hash types are supported.

The application is already running on port `8000`, but it is not expose to the internet (it needs to be exposed externally so Okta can make access it.)

Use ngrok to get a public URL for the locally running service:

```bash
ngrok http 8000
```

### Register the application with Okta 

These details are not repeated here, see: https://developer.okta.com/docs/guides/password-import-inline-hook/nodejs/main/

Values:
- **Endpoint** - `{your-ngrok-url}/pwhook`
- **Authentication field** - Authorization
- **Authentication secret** - `Basic dXNlcjpva3RhaG9va3Nwdw==`

> **NOTE:** This uses basic authentication and a static username/password. This value can be calculated using a command `echo <username>:<password> | base64`. But don't forget the `Basic ` prefix!

### Test out the password import hook

Once again open a private browser (or clear your cookies), navigate to `http://localhost:8080` and login with `user2@example.com` and `password`.
This user had an unsupported hash, here is the flow of events:

- Navigate to your web-app
- web-app redirects to Okta to sign-in
- Type username and password
- Okta makes a REST request to your password-validation REST application
- The password-validation service validates the password and response to Okta
- Okta stores a hash of the user's password
- The user is redirected back to the web-app

