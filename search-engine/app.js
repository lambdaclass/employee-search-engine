import weaviate from 'weaviate-ts-client';
import express from 'express';
import bodyParser from 'body-parser';

export const client = weaviate.client({
    scheme: 'http',
    host: 'localhost:8080',
});

const schemaRes = await client.schema.getter().do();
console.log(schemaRes)

const app = express();
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

export default app;
