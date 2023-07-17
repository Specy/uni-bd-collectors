import { app, BrowserWindow, ipcMain as ipc, protocol, dialog, shell } from "electron";
import url from "url";
import path from "path";
import { PATHS, ROOT_PATH } from "./utils";
import serve from "electron-serve";
import log from "electron-log";
import { CollectorsDb } from "./db/collectors-db";
import { createDatabase } from "./db/db";
const isDev = !app.isPackaged

try {
    log.transports.file.resolvePath = () => path.join(ROOT_PATH, 'logs/main.log');
    Object.assign(console, log.functions)
    if (require('electron-squirrel-startup')) app.quit();
} catch (e) {
    console.error(e)
}
try {
    //require('electron-reloader')(module)
} catch (e) { }



const loadURL = serve({ directory: PATHS.svelteDist });

let splash: BrowserWindow | undefined
function loadSplash() {
    if (hasLoaded) return;
    splash = new BrowserWindow({
        width: 1280,
        height: 720,
        minWidth: 1280,
        minHeight: 720,
        center: true,
        backgroundColor: "#171A21",
        title: "Loading Collectors...",
        icon: path.join(PATHS.electronStatic, "/icons/icon.png"),
        frame: false,
    })
    splash.loadURL(
        `file://${path.join(PATHS.electronStatic, "/splash.html")}`
    )
    splash.on('closed', () => (splash = undefined));
    splash.webContents.on('did-finish-load', () => {
        splash?.show()
    });
}

let hasLoaded = false;
function createWindow() {
    const win = new BrowserWindow({
        width: 1280,
        height: 720,
        minWidth: 720,
        minHeight: 720,
        title: "Scapix",
        backgroundColor: "#171A21",
        center: true,
        icon: path.join(PATHS.electronStatic, "/icons/icon.png"),
        show: false,
        titleBarStyle: 'hidden',
        webPreferences: {
            preload: path.join(PATHS.electronClient, "/ipc/api.js")
        },
    });
    function load() {
        if (isDev) {
            win.loadURL("http://localhost:3123")
        } else {
            loadURL(win);
        }
    }
    load()
    win.webContents.on("did-fail-load", () => {
        console.log("Failed to load, retrying in 500ms");
        setTimeout(load, 500);
    })
    win.webContents.on('did-finish-load', () => {
        splash?.close();
        //win.show();
        hasLoaded = true;
        setTimeout(() => {
            win.setAlwaysOnTop(false)
        }, 200)
    })
    setUpIpc(win);
}


function sendLog(type: "error" | "warn" | "log", message: string, timeout = 5000) {
    ipc.emit("log-to-renderer", { type, message, timeout })
}


async function setUpIpc(win: BrowserWindow) {
    //all files that are either being converted or are queued to be converted
    ipc.handle("minimize", () => win.minimize())
    ipc.handle("maximize", () => win.maximize())
    ipc.handle("close", () => win.close())
    ipc.handle("ping", () => "pong")
    ipc.handle("toggle-maximize", () => {
        if (win.isMaximized()) {
            win.unmaximize();
        } else {
            win.maximize();
        }
    })

    ipc.handle("open-dir", (e, dir: string) => {
        const isRelative = !path.isAbsolute(dir);
        if (isRelative) {
            shell.openPath(path.resolve(path.join(PATHS.root, dir)));
        } else {
            shell.openPath(path.resolve(dir));
        }
    })
    ipc.on("goto-external", (e, url) => {
        shell.openExternal(url);
    })
    win.on("maximize", () => win.webContents.send("maximize-change", true))
    win.on("unmaximize", () => win.webContents.send("maximize-change", false))

    const db = await CollectorsDb.new("collectors")
    console.log(await db.test())
}


app.on('window-all-closed', async () => {
    if (process.platform !== 'darwin') app.quit()
})
function disposeAndQuit() {
    app.quit()
}
process.on('SIGINT', disposeAndQuit)
process.on('SIGTERM', disposeAndQuit)
process.on('SIGQUIT', disposeAndQuit)
app.whenReady().then(() => {
    loadSplash()
    createWindow()
    protocol.registerFileProtocol('resource', (request, callback) => {
        const filePath = url.fileURLToPath('file://' + request.url.slice('resource://'.length))
        callback(filePath)
    })
})