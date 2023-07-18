import { app } from "electron";

import path from "path";

export const ROOT_PATH = app.getAppPath()

export const PATHS = {
    root: ROOT_PATH,
    svelteDist: path.join(ROOT_PATH, "/client/build"),
    electronDist: path.join(ROOT_PATH, "/electron/dist"),
    electronClient: path.join(ROOT_PATH, "/electron/dist/client"),
    electronStatic: path.join(ROOT_PATH, "/electron/static"),
    sqlScripts: path.join(ROOT_PATH, "/electron/src/db/sql-scripts"),
    hasRanOnce: path.join(ROOT_PATH, "/electron/has-ran-once.txt"),
}





export type Result<T, E> = {
    ok: true
    value: T
} | {
    ok: false
    error: E
    trace?: string
}
export function Ok<T>(value: T): Result<T, never> {
    return {
        ok: true,
        value
    }
}
export function Err<E>(error: E, trace?: string): Result<never, E>{
    return {
        ok: false,
        error,
        trace
    }
}