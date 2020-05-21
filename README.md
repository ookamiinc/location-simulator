# location-simulator

Send fake locations to test tracking-ui

## How to setup

1. Go to the Firebase console and under `Project Settings` -> `Service Accounts` -> `Firebase Admin SDK` click on `GENERATE NEW PRIVATE KEY`. Save the json file and move this directory as `firebase-adminsdk.json`.
2. Update `FIREBASE_BASE_URI` for your project.
3. Change COMPETITION_ID and CAR_ID for your use.

## How to run simulator

```bash
$ bundle install
$ bundle exec ruby simulate.rb
```
