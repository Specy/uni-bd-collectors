import { app, BrowserWindow, ipcMain as ipc, protocol, dialog, shell } from "electron";
import url from "url";
import path from "path";
import { PATHS, ROOT_PATH } from "./utils";
import serve from "electron-serve";
import log from "electron-log";
import { CollectorsDb } from "./db/collectors-db";
import fs from "fs"
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
function createWindow(db: CollectorsDb) {
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
        win.show()
        hasLoaded = true;
        setTimeout(() => {
            win.setAlwaysOnTop(false)
        }, 200)
    })
    setUpIpc(win, db);
}


function sendLog(type: "error" | "warn" | "log", message: string, timeout = 5000) {
    ipc.emit("log-to-renderer", { type, message, timeout })
}


async function setUpIpc(win: BrowserWindow, db: CollectorsDb) {
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
    ipc.handle('get-collections-of-collector', async (e, { collectorId, includeVisibleCollections }) => {
        return await db.getCollectionsOfCollector(collectorId, includeVisibleCollections)
    })
    ipc.handle("get-collection", async (e, { collectionId }) => {
        return await db.getCollection(collectionId)
    })
    ipc.handle("get-disc", async (e, { discId }) => {
        return await db.getDisc(discId)
    })
    ipc.handle("get-discs-of-collection", async (e, { collectionId }) => {
        return await db.getDiscsOfCollection(collectionId)
    })
    ipc.handle("set-collection-visibility", async (e, { collectionId, isVisible }) => {
        await db.setCollectionVisibility(collectionId, isVisible)
    })
    ipc.handle('login-user', async (e, { username, email }) => {
        return await db.loginUser(username, email)
    })
    ipc.handle('get-collector-by-mail', async (e, { email }) => {
        return await db.getCollectorByMail(email)
    })
    ipc.handle('set-collector-in-collection', async (e, { collectionId, collectorId, isInCollection }) => {
        await db.setCollectorInCollection(collectionId, collectorId, isInCollection)
    })
    ipc.handle('create-collector', async (e, { username, email }) => {
        return await db.createCollector(username, email)
    })
    ipc.handle('get-track', async (e, { trackId }) => {
        return await db.getTrack(trackId)
    })
    ipc.handle("create-collection", async (e, { name, isPublic, ownerId }) => {
        return await db.createCollection(name, ownerId, isPublic)
    })
    ipc.handle('get-population-options', (e) => {
        return db.getPopulationOptions()
    })
    ipc.handle('seach-disc', async (e, { title, artistName, searchInOwnedDiscs, searchInSharedDiscs, searchInPublicDiscs }) => {
        return await db.searchDisc(title, artistName, searchInOwnedDiscs, searchInSharedDiscs, searchInPublicDiscs)
    })
    ipc.handle('search-disc-best-matches', async (e, { title, barcode, artistName }) => {
        return await db.findBestDiscMatches(title, barcode, artistName)
    })
    ipc.handle('artist-name-autocomplete', async (e, { artistName }) => {
        return await db.getArtistsAutocomplete(artistName)
    })
    ipc.handle('label-name-autocomplete', async (e, { labelName }) => {
        return await db.getLabelsAutocomplete(labelName)
    })
    ipc.handle('create-disc', async (e, { disc }) => {
        return await db.createDisc(disc)
    })
    ipc.handle('create-artist', async (e, { artist }) => {
        return await db.createArtist(artist)
    })
    ipc.handle('create-label', async (e, { label }) => {
        return await db.createLabel(label)
    })
    ipc.handle('remove-track', async (e, { trackId }) => {
        return await db.removeTrack(trackId)
    })  
    ipc.handle('remove-disc', async (e, { discId }) => {
        return await db.removeDisc(discId)
    })
    win.on("maximize", () => win.webContents.send("maximize-change", true))
    win.on("unmaximize", () => win.webContents.send("maximize-change", false))
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
app.whenReady().then(async () => {
    loadSplash()
    const hasRanOnce = fs.existsSync(PATHS.hasRanOnce)
    const db = await CollectorsDb.new("collectors", undefined, !hasRanOnce)
    if (!hasRanOnce) {
        fs.writeFileSync(PATHS.hasRanOnce, "1")
    }
    createWindow(db)
    protocol.registerFileProtocol('resource', (request, callback) => {
        const filePath = url.fileURLToPath('file://' + request.url.slice('resource://'.length))
        callback(filePath)
    })
})