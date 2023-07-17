import mysql, { ConnectionOptions } from "mysql2/promise";


export const DEFAULT_CONNECTION = {
    host: "localhost",
    port: 3306,
    user: "root",
    password: "root",
} satisfies ConnectionOptions

export async function createDatabase(config: ConnectionOptions = DEFAULT_CONNECTION) {
    return await mysql.createConnection(config)
}