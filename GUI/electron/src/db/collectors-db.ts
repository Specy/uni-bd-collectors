import { Connection, ConnectionOptions } from "mysql2/promise";
import path from "path";
import fs from "fs/promises";
import { PATHS } from "../utils";
import { DEFAULT_CONNECTION, createDatabase } from "./db";
import { Artist, ArtistRole, Collection, CollectionInfo, CollectionsOfCollector, Collector, Disc, DiscInfo, Image, LabelInfo, PopulationOptions, Track, TrackInfo } from "common/types/CollectorsTypes";
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
    async createCollector(username: string, email: string) {
        await this.db.execute("CALL add_collector(?, ?)", [username, email]) as ProcedureResponse
        const collector = await this.getCollectorByMail(email)
        return collector
    }
    async getCollectionInfo(collectionId: number) {
        const [collection] = await this.db.execute("CALL get_collection(?)", [collectionId]) as ProcedureResponse
        if (!collection.length || !collection[0].length) return null
        return parseCollectionInfo(collection[0][0])
    }
    async getCollection(collectionId: number) {
        const disks = await this.getDiscsOfCollection(collectionId)
        const collection = await this.getCollectionInfo(collectionId)
        if (!collection) return null
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
    async createCollection(name: string, ownerId: number, isPublic: boolean) {
        const [collection] = await this.db.execute("CALL create_collection(?, ?, ?)", [name, ownerId, isPublic]) as ProcedureResponse
        if (!collection.length || !collection[0].length) return null
        const id = collection[0][0].collection_id
        return await this.getCollectionInfo(id)
    }
    async getGenres() {
        const [genres] = await this.db.execute("CALL get_genres()") as ProcedureResponse
        if (!genres.length) return null
        return genres[0].map((e) => e.genre_name)
    }
    async getConservationStatuses() {
        const [statuses] = await this.db.execute("CALL get_conditions()") as ProcedureResponse
        if (!statuses.length) return null
        return statuses[0].map((e) => e.condition_name)
    }
    async getFormats() {
        const [formats] = await this.db.execute("CALL get_formats()") as ProcedureResponse
        if (!formats.length) return null
        return formats[0].map((e) => e.format_name)
    }
    async getImageTypes() {
        const [types] = await this.db.execute("CALL get_image_types()") as ProcedureResponse
        if (!types.length) return null
        return types[0].map((e) => e.image_type_name)
    }
    async getPopulationOptions() {
        const [genres, statuses, formats, imageTypes] = await Promise.all([
            this.getGenres(),
            this.getConservationStatuses(),
            this.getFormats(),
            this.getImageTypes()
        ])
        return {
            genres,
            statuses,
            formats,
            imageTypes
        } as PopulationOptions
    }
    async searchDisc(title: string | null, artistName: string | null, searchInOwnedDiscs: boolean, searchInSharedDiscs: boolean, searchInPublicDiscs: boolean) {
        const [discs] = await this.db.execute("CALL search_discs(?, ?, ?, ?, ?)", [title, artistName, searchInOwnedDiscs, searchInSharedDiscs, searchInPublicDiscs]) as ProcedureResponse
        if (!discs.length) return null
        return discs[0].map(parseDiskInfo)
    }
    async findBestDiscMatches(title: string | null, barcode: string | null, artistName: string | null) {
        const [discs] = await this.db.execute("CALL find_best_match_of_disc_from(?, ?, ?)", [barcode, title, artistName]) as ProcedureResponse
        if (!discs.length) return null
        return discs[0].map(parseDiskInfo)
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
        const [tracks] = await this.db.execute("CALL get_disc_tracks(?)", [discId]) as ProcedureResponse
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

    async getArtistsAutocomplete(artistText: string) {
        const [artists] = await this.db.execute("CALL get_artist_autocomplete(?)", [artistText]) as ProcedureResponse
        if (!artists.length) return null
        return artists[0].map(parseArtist)
    }
    async getLabelsAutocomplete(labelText: string) {
        const [labels] = await this.db.execute("CALL get_label_autocomplete(?)", [labelText]) as ProcedureResponse
        if (!labels.length) return null
        return labels[0].map(parseLabel)
    }
    async getLabel(labelId: number) {
        const [label] = await this.db.execute("CALL get_label(?)", [labelId]) as ProcedureResponse
        if (!label.length || !label[0].length) return null
        return parseLabel(label[0][0])
    }
    async getDisc(discId: number) {
        const disc = await this.getDiscInfo(discId)
        if (!disc) return null
        const images = await this.getImagesOfDisc(discId)!
        const tracks = await this.getTracksOfDisc(discId)!
        const artist = await this.getArtist(disc.artistId)
        const label = await this.getLabel(disc.labelId)
        return {
            ...disc,
            artist,
            label,
            images,
            tracks
        } as Disc
    }
    async getTrackContributors(trackId: number) {
        const [contributors] = await this.db.execute("CALL get_track_contributors(?)", [trackId]) as ProcedureResponse
        if (!contributors.length) return null
        return contributors[0].map((e) => {
            return {
                artist: parseArtist(e),
                role: e.contribution_type
            } as ArtistRole
        })
    }
    async getTrack(trackId: number) {
        const [track] = await this.db.execute("CALL get_track(?)", [trackId]) as ProcedureResponse
        if (!track.length || !track[0].length) return null
        const parsed = parseTrackInfo(track[0][0])
        const contributors = await this.getTrackContributors(trackId)
        return {
            ...parsed,
            artists: contributors
        } as Track
    }
    async createImage(discId: number, image: Image) {
        await this.db.execute("CALL create_image(?, ?, ?)", [image.src, image.kind, discId])
    }
    async createTrack(track: TrackInfo) {
        await this.db.execute("CALL create_track(?, ?, ?)", [track.duration, track.title, track.discId])
    }
    async getArtistByStageName(stageName: string) {
        const [artist] = await this.db.execute("CALL get_artist_by_stage_name(?)", [stageName]) as ProcedureResponse
        if (!artist.length || !artist[0].length) return null
        return parseArtist(artist[0][0])
    }
    async removeTrack(trackId: number) {
        await this.db.execute("CALL remove_track(?)", [trackId])
    }
    async removeDisc(discId: number) {
        await this.db.execute("CALL remove_disc(?)", [discId])
    }
    async createDisc(disc: Disc) {
        const [result] = await this.db.execute('CALL create_disc(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [
            disc.title,
            disc.barcode,
            disc.year,
            disc.quantity,
            disc.genre,
            disc.format,
            disc.label.id,
            disc.collectionId,
            disc.conservationStatus,
            disc.artist.id
        ]) as ProcedureResponse
        if (!result.length || !result[0].length) throw new Error("Disc not created")
        const id = result[0][0].disc_id
        await Promise.all([
            disc.tracks.map(t => ({...t, discId: id })).map((track) => this.createTrack(track)),
            disc.images.map((image) => this.createImage(id, image))
        ])
        return id
    }
    async createLabel(label: LabelInfo) {
        await this.db.execute("CALL create_label(?)", [label.name])
    }
    async createArtist(artist: Artist) {
        await this.db.execute("CALL create_artist(?, ?)", [artist.stageName, artist.name])
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
function parseLabel(label: any): LabelInfo {
    return {
        id: label.label_id,
        name: label.label_name
    }
}
function parseTrackInfo(track: any): TrackInfo {
    return {
        id: track.track_id,
        title: track.track_title,
        duration: track.track_length,
        discId: track.disc_id
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
        artist: disk.artist_stage_name,
        labelId: disk.label_id,
        artistId: disk.artist_id,
        collectionId: disk.collection_id
    }
}

function removeDelimiter(str: string) {
    str = str.replace("DELIMITER $", "").replace("DELIMITER ;", "")
    return str.replaceAll("END$", "END;")
}


type ProcedureResponse<T = any> = [[T[], any[]], any]