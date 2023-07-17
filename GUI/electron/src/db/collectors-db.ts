import { Connection, ConnectionOptions } from "mysql2/promise";
import path from "path";
import fs from "fs/promises";
import { PATHS } from "../utils";
import { DEFAULT_CONNECTION, createDatabase } from "./db";
//db.execute is a prepared statement
export class CollectorsDb{
    private db: Connection;
    private isInitialized = false;
    private initPromise: Promise<void> | null = null;
    constructor(db: Connection){
        this.db = db;
    }

    private static async ensureDatabaseExists(database: string, config: ConnectionOptions = DEFAULT_CONNECTION){
        delete config.database
        const db = await createDatabase(config)
        await db.execute(`CREATE DATABASE IF NOT EXISTS ${database}`)
        await db.end()   
    }
    static async new(database: string, config: ConnectionOptions = DEFAULT_CONNECTION){
        await CollectorsDb.ensureDatabaseExists(database, config)
        config = {...config, database, multipleStatements: true}
        const db =  new CollectorsDb(await createDatabase(config))
        await db.init()
        return db
    }
    async init(includeMock: boolean = true, reset: boolean = true): Promise<void>{
        if(this.initPromise) return this.initPromise
        if(this.isInitialized) return Promise.resolve()
        this.initPromise = new Promise(async (resolve, reject) => {
            try{
                const [
                    databaseCreation,
                    mockDataCreation,
                    proceduresCreation,
                    triggersCreation,
                    resetScript
                ] = await Promise.all([
                    fs.readFile(path.join(PATHS.sqlScripts, 'database_creation_script.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'mock_data_script.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'procedures.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'triggers_script.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'reset.sql'), "utf-8"),
                ])
                if(reset) await this.db.query(resetScript)
                await this.db.query(databaseCreation)
                await this.db.query(removeDelimiter(triggersCreation))
                await this.db.query(removeDelimiter(proceduresCreation))
                if(includeMock) await this.db.query(mockDataCreation)
                this.isInitialized = true
                this.initPromise = null
                resolve()
            }catch(e){
                reject(e)
            }
        })
        return this.initPromise
    }   
    async test(){
        const [rows] = await this.db.execute("CALL find_best_match_of_disc_from('1234567890', NULL, NULL)")
        return rows
    }
}


function removeDelimiter(str: string){
    str = str.replace("DELIMITER $", "").replace("DELIMITER ;", "")
    return str.replaceAll("END$","END;")
}