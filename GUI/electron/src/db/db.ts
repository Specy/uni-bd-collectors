import mysql, { ConnectionOptions } from "mysql2/promise";


export const DEFAULT_CONNECTION = {
    host: 'localhost',
    user: 'root',
    database: 'test'
} satisfies ConnectionOptions

export async function createDatabase(config: ConnectionOptions = DEFAULT_CONNECTION) {
    return await mysql.createConnection(config)
}