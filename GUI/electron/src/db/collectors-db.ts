import { Connection } from "mysql2/promise";

//db.execute is a prepared statement
export class CollectorsDb{
    private db: Connection;
    constructor(db: Connection){
        this.db = db;
    }
    async raw(...props: Parameters<Connection['execute']>): Promise<ReturnType<Connection['execute']>>{
        return this.db.execute(...props)
    }
}
