const { Client } = require('pg');
async function dumpSchema() {
    const client = new Client('postgresql://postgres:postgres@localhost:5432/musicroom');
    await client.connect();
    const res = await client.query("SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema='public'");
    console.log(JSON.stringify(res.rows, null, 2));
    await client.end();
}
dumpSchema();