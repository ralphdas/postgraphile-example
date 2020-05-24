# Backend Module
The backend module can be run by starting the express application itself as below
```
yarn dev
```

Or by using the PostGraphile CLI

```
npx postgraphile
    --connection postgres://forum_example_postgraphile:xyz@localhost/forum_db
    --schema forum_example
    --default-role forum_example_anonymous
    --jwt-secret keyboard_kitten
    --append-plugins @graphile-contrib/pg-simplify-inflector
```