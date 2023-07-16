import { Connection } from "mysql2/promise";
import path from "path";
import fs from "fs/promises";
import { PATHS } from "utils";
//db.execute is a prepared statement
export class CollectorsDb{
    private db: Connection;
    private isInitialized = false;
    private initPromise: Promise<void> | null = null;
    constructor(db: Connection){
        this.db = db;
    }

    async init(includeMock?: boolean, reset?: boolean): Promise<void>{
        if(this.initPromise) return this.initPromise
        if(this.isInitialized) return Promise.resolve()
        this.initPromise = new Promise(async (resolve, reject) => {
            try{
                const [
                    databaseCreation,
                    triggersCreation,
                    mockDataCreation,
                    proceduresCreation,
                    resetScript
                ] = await Promise.all([
                    fs.readFile(path.join(PATHS.sqlScripts, 'database_creation_script.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'mock_data_script.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'procedures.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'triggers_script.sql'), "utf-8"),
                    fs.readFile(path.join(PATHS.sqlScripts, 'reset.sql'), "utf-8"),
                ])
                await this.db.execute(databaseCreation)
                await this.db.execute(triggersCreation)
                if(includeMock) await this.db.execute(mockDataCreation)
                await this.db.execute(proceduresCreation)
                if(reset) await this.db.execute(resetScript)
                this.isInitialized = true
                this.initPromise = null
                resolve()
            }catch(e){
                reject(e)
            }
        })
        return this.initPromise
    }   

    async raw(...props: Parameters<Connection['execute']>): Promise<ReturnType<Connection['execute']>>{
        return this.db.execute(...props)
    }
}
