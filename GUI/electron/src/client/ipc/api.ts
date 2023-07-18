import { Artist, Collection, CollectionInfo, CollectionsOfCollector, Collector, Disc, DiscInfo, LabelInfo, PopulationOptions, Track } from "../../common/types/CollectorsTypes";
import { contextBridge, ipcRenderer as ipc } from "electron";

type EventListener = {
    id: string,
    callback: (...args: any[]) => void
}
class EventListeners {
    private listeners = new Map<string, EventListener[]>();
    static generateId() {
        return Math.random().toString(36).substring(2, 9);
    }
    addListener(event: string, listener: EventListener) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, []);
        }
        this.listeners.get(event)?.push(listener);
    }
    removeListener(event: string, listener: EventListener | string | Function) {
        if (!this.listeners.has(event)) return;
        const listeners = this.listeners.get(event)!;
        const index = listeners.findIndex((l) => {
            if (typeof listener === "string") return l.id === listener;
            if (typeof listener === "function") return l.callback === listener;
            return l.id === listener.id;
        });
        if (index < 0) return;
        return listeners.splice(index, 1)[0];
    }
}

const eventListeners = new EventListeners();
const controls = {
    close: async () => {
        return ipc.invoke("close")
    },
    minimize: async () => {
        return ipc.invoke("minimize")
    },
    maximize: async () => {
        return ipc.invoke("maximize")
    },
    toggleMaximize: async () => {
        return ipc.invoke("toggle-maximize")
    },
    addOnMaximizationChange: (callback: (isMaximized: boolean) => void) => {
        const id = EventListeners.generateId();
        const listener = {
            id,
            callback: (e: any, data: any) => {
                callback(data);
            }
        }
        eventListeners.addListener("maximize-change", listener);
        ipc.on("maximize-change", listener.callback);
        return id;
    },
    addOnLog: (callback: (type: "error" | "log" | "warn", message: string, timeout?: number) => void) => {
        const id = EventListeners.generateId()
        const listener = {
            id,
            callback: (e: any, data: any) => {
                const { type, message, timeout } = data
                callback(type, message, timeout)
            }
        }
        eventListeners.addListener("log", listener)
        ipc.on("log-to-renderer", listener.callback)
    },
    removeOnLog: (id: string) => {
        const listener = eventListeners.removeListener("log-to-renderer", id);
        if (!listener) return;
        ipc.removeListener("log-to-renderer", listener.callback);
    },
    removeOnMaximizationChange: (id: string) => {
        const listener = eventListeners.removeListener("maximize-change", id);
        if (!listener) return;
        ipc.removeListener("maximize-change", listener.callback);
    },
}
export type Controls = typeof controls;
contextBridge.exposeInMainWorld("controls", controls)




const api = {
    ping: async () => {
        return ipc.invoke("ping")
    },
    getCollectionsOfCollector: async (collectorId: number, includeVisibleCollections: boolean) => {
        return ipc.invoke("get-collections-of-collector", { collectorId, includeVisibleCollections }) as Promise<CollectionsOfCollector | null>
    },
    getCollection: async (collectionId: number) => {
        return ipc.invoke("get-collection", { collectionId }) as Promise<Collection | null>
    },
    getDiscsOfCollection: async (collectionId: number) => {
        return ipc.invoke("get-discs-of-collection", { collectionId }) as Promise<DiscInfo[] | null>
    },
    getDisc: async (discId: number) => {
        return ipc.invoke("get-disc", { discId }) as Promise<Disc | null>
    },
    createCollector: async (username: string, email: string) => {
        return ipc.invoke("create-collector", { username, email }) as Promise<Collector | null>
    },
    setCollectionVisibility: async (collectionId: number, isVisible: boolean) => {
        return ipc.invoke("set-collection-visibility", { collectionId, isVisible }) as Promise<void>
    },
    loginUser: async (username: string, email: string) => {
        return ipc.invoke("login-user", { username, email }) as Promise<Collector | null>
    },
    setCollectorInCollection: async (collectionId: number, collectorId: number, isInCollection: boolean) => {
        return ipc.invoke("set-collector-in-collection", { collectionId, collectorId, isInCollection }) as Promise<void>
    },
    getCollectorByMail: async (email: string) => {
        return ipc.invoke("get-collector-by-mail", { email }) as Promise<Collector | null>
    },
    getTrack: async (trackId: number) => {
        return ipc.invoke("get-track", { trackId }) as Promise<Track | null>
    },
    createCollection: async (name: string, isPublic: boolean, ownerId: number) => {
        return ipc.invoke("create-collection", { name, isPublic, ownerId }) as Promise<CollectionInfo | null>
    },
    getPopulationOptions: async () => {
        return ipc.invoke("get-population-options") as Promise<PopulationOptions | null>
    },
    searchDisc: async (title: string | null, artistName: string | null, searchInOwnedDiscs: boolean, searchInSharedDiscs: boolean, searchInPublicDiscs: boolean) => {
        return ipc.invoke("seach-disc", { title, artistName, searchInOwnedDiscs, searchInSharedDiscs, searchInPublicDiscs }) as Promise<DiscInfo[] | null>
    },
    searchDiscBestMatches: async(title: string | null, barcode: string | null, artistName: string | null) => {
        return ipc.invoke("search-disc-best-matches", { title, barcode, artistName }) as Promise<DiscInfo[] | null>
    },
    artistNameAutocomplete: async (artistName: string) => {
        return ipc.invoke("artist-name-autocomplete", { artistName }) as Promise<Artist[] | null>
    },
    labelNameAutocomplete: async (labelName: string) => {
        return ipc.invoke("label-name-autocomplete", { labelName }) as Promise<LabelInfo[] | null>
    },
    createDisc: async (disc: Disc) => {
        return ipc.invoke("create-disc", { disc }) as Promise<number>
    },
    createArtist: async (artist: Artist) => {
        return ipc.invoke("create-artist", { artist }) as Promise<void>
    },
    createLabel: async (label: LabelInfo) => {
        return ipc.invoke("create-label", { label }) as Promise<void>
    },
    removeTrack: async (trackId: number) => {
        return ipc.invoke("remove-track", { trackId }) as Promise<void>
    },
    removeDisc: async (discId: number) => {
        return ipc.invoke("remove-disc", { discId }) as Promise<void>
    }
}

export type Api = typeof api;
contextBridge.exposeInMainWorld("api", api)