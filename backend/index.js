import express from 'express'
import { postgraphile } from 'postgraphile'
import { config } from 'dotenv'
import pgSimplplifyInflector from '@graphile-contrib/pg-simplify-inflector'

// run config to import all the environment variables
config()

const app = express()

app.use(
  postgraphile(
    process.env.GRAPHILE_HOST,
    process.env.GRAPHILE_SCHEMA,
    {
      watchPg: true,
      graphiql: true,
      enhanceGraphiql: true,
      pgDefaultRole: process.env.GRAPHILE_DEFAULT_ROLE,
      jwtSecret: process.env.GRAPHILE_JWT_SECRET,
      jwtPgTypeIdentifier: process.env.GRAPHILE_TOKEN_TYPE,
      appendPlugins: [
        pgSimplplifyInflector
      ],
      ownerConnectionString: process.env.GRAPHILE_DB_OWNER
    }
  )
)

app.listen(process.env.DEFAULT_PORT, () => {
  console.log(`Backend Application listening on port: ${process.env.DEFAULT_PORT}`)
})
