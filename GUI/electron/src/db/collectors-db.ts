import { Connection, ConnectionOptions } from "mysql2/promise";
import path from "path";
import fs from "fs/promises";
import { PATHS } from "../utils";
import { DEFAULT_CONNECTION, createDatabase } from "./db";
import { Artist, Collection, CollectionInfo, CollectionsOfCollector, Collector, Disc, DiscInfo, Image, Track, TrackInfo } from "common/types/CollectorsTypes";
//db.execute is a prepared statement
export class CollectorsDb {
    private db: Connection;
    private isInitialized = false;
    private initPromise: Promise<void> | null = null;
    constructor(db: Connection) {
        this.db = db;
    }

    private static async ensureDatabaseExists(database: string, config: ConnectionOptions = DEFAULT_CONNECTION) {
        delete config.database
        const db = await createDatabase(config)
        await db.execute(`CREATE DATABASE IF NOT EXISTS ${database}`)
        await db.end()
    }
    static async new(database: string, config: ConnectionOptions = DEFAULT_CONNECTION) {
        await CollectorsDb.ensureDatabaseExists(database, config)
        config = { ...config, database, multipleStatements: true }
        const db = new CollectorsDb(await createDatabase(config))
        await db.init()
        return db
    }
    async init(includeMock: boolean = false, reset: boolean = false): Promise<void> {
        if (this.initPromise) return this.initPromise
        if (this.isInitialized) return Promise.resolve()
        this.initPromise = new Promise(async (resolve, reject) => {
            try {
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
                if (reset) await this.db.query(resetScript)
                await this.db.query(databaseCreation)
                await this.db.query(removeDelimiter(triggersCreation))
                await this.db.query(removeDelimiter(proceduresCreation))
                if (includeMock) await this.db.query(mockDataCreation)
                this.isInitialized = true
                this.initPromise = null
                resolve()
            } catch (e) {
                reject(e)
            }
        })
        return this.initPromise
    }
    async getCollectionsOfCollector(collectorId: number, includeVisibleCollections: boolean = false) {
        const result = {
            collections: [],
            visibleCollections: []
        } as CollectionsOfCollector
        const [collections] = await this.db.execute("CALL get_collections_of_collector(?)", [collectorId]) as ProcedureResponse
        result.collections = collections[0].map(parseCollectionInfo)
        if (includeVisibleCollections) {
            const [visibleCollections] = await this.db.execute("CALL get_visible_collections_of_collector(?)", [collectorId]) as ProcedureResponse
            result.visibleCollections = visibleCollections[0].map(parseCollectionInfo)
        }
        return result
    }
    async getDiscsOfCollection(collectionId: number) {
        const [disks] = await this.db.execute("CALL get_discs_of_collection(?)", [collectionId]) as ProcedureResponse
        if (!disks.length) return null
        return disks[0].map(parseDiskInfo)
    }
    async getCollaboratorsOfCollection(collectionId: number) {
        const [collaborators] = await this.db.execute("CALL get_collectors_of_collection(?)", [collectionId]) as ProcedureResponse
        if (!collaborators.length) return null
        return collaborators[0].map(parseCollector)
    }
    async setCollectionVisibility(collectionId: number, isVisible: boolean) {
        await this.db.execute("CALL set_collection_visibility(?, ?)", [collectionId, isVisible])
    }   
    async loginUser(username: string, email: string) {
        const [user] = await this.db.execute("CALL login_user(?, ?)", [username, email]) as ProcedureResponse
        if (!user.length || !user[0].length) return null
        return parseCollector(user[0][0])
    }
    async getCollector(collectorId: number) {
        const [collector] = await this.db.execute("CALL get_collector(?)", [collectorId]) as ProcedureResponse
        if (!collector.length || !collector[0].length) return null
        return parseCollector(collector[0][0])
    }
    async getCollectionInfo(collectionId: number) {
        const [collection] = await this.db.execute("CALL get_collection(?)", [collectionId]) as ProcedureResponse
        if (!collection.length || !collection[0].length) return null
        return parseCollectionInfo(collection[0][0])
    }
    async getCollection(collectionId: number) {
        const disks = await this.getDiscsOfCollection(collectionId)
        const collection = await this.getCollectionInfo(collectionId)
        if(!collection) return null
        const collaborators = await this.getCollaboratorsOfCollection(collectionId)
        const owner = await this.getCollector(collection.ownerId)
        return {
            ...collection,
            disks,
            collectors: collaborators,
            owner: owner!
        } as Collection
    }
    async getImagesOfDisc(discId: number) {
        const [images] = await this.db.execute("CALL get_images_of_disc(?)", [discId]) as ProcedureResponse
        if (!images.length) return null
        return images[0].map(parseImage)
    }
    async getArtist(artistId: number) {
        const [artist] = await this.db.execute("CALL get_artist(?)", [artistId]) as ProcedureResponse
        if (!artist.length || !artist[0].length) return null
        return parseArtist(artist[0][0])
    }
    async getDiscInfo(discId: number) {
        const [discInfo] = await this.db.execute("CALL get_disc(?)", [discId]) as ProcedureResponse
        if (!discInfo.length) return null
        return parseDiskInfo(discInfo[0][0])
    }
    async getTracksOfDisc(discId: number) {
        const [tracks] = await this.db.execute("CALL get_tracks_of_disc(?)", [discId]) as ProcedureResponse
        if (!tracks.length) return null
        return tracks[0].map(parseTrackInfo)
    }
    async getCollectorByMail(email: string) {
        const [collector] = await this.db.execute("CALL get_collector_by_mail(?)", [email]) as ProcedureResponse
        if (!collector.length || !collector[0].length) return null
        return parseCollector(collector[0][0])
    }

    async setCollectorInCollection(collectionId: number, collectorId: number, isInCollection: boolean) {
        await this.db.execute("CALL set_collector_in_collection(?, ?, ?)", [collectionId, collectorId, isInCollection])
    }
    async getDisc(discId: number) {
        const disc = await this.getDiscInfo(discId)
        if (!disc) return null
        const images = await this.getImagesOfDisc(discId)!
        const tracks = await this.getTracksOfDisc(discId)!
        return {
            ...disc,
            images,
            tracks
        } as Disc
    }
}

function parseCollectionInfo(collection: any): CollectionInfo {
    return {
        id: collection.collection_id,
        isPublic: Boolean(collection.is_public),
        name: collection.collection_name,
        ownerId: Number(collection.collector_id)
    }
}
function parseCollector(col: any): Collector {
    return {
        id: col.collector_id,
        email: col.collector_email,
        username: col.collector_username
    }
}

function parseImage(image: any): Image {
    return {
        kind: image.image_format,
        src: image.image_path
    }

}

function parseArtist(artist: any): Artist {
    return {
        id: artist.artist_id,
        name: artist.artist_name,
        stageName: artist.artist_stage_name
    }

}

function parseTrackInfo(track: any): TrackInfo {
    return {
        id: track.track_id,
        title: track.track_title,
        duration: track.track_length
    }
}
function parseDiskInfo(disk: any): DiscInfo {
    return {
        id: disk.disc_id,
        title: disk.disc_title,
        barcode: disk.disc_barcode,
        year: disk.disc_release_year,
        quantity: disk.disc_number_of_copies,
        genre: disk.disc_genre,
        format: disk.disc_format,
        conservationStatus: disk.disc_status,
        label: disk.label_name,
        artist: disk.artist_stage_name
    }
}

function removeDelimiter(str: string) {
    str = str.replace("DELIMITER $", "").replace("DELIMITER ;", "")
    return str.replaceAll("END$", "END;")
}


type ProcedureResponse<T = any> = [[T[], any[]], any]