export type DiscInfo = {
    id: number,
    title: string,
    year: number,
    genre: string,
    format: string,
    label: string,
    quantity: number,
    barcode?: string,
    artist: string,
    conservationStatus: string,
}

export type Disc = DiscInfo & {
    tracks: TrackInfo[],
    images: Image[],
}

export type TrackInfo = {
    id: number,
    title: string,
    duration: number,
}
export type Track = TrackInfo &{
    artists: ArtistRole[]
}

export type ArtistRole = {
    artist: Artist,
    role: string,
}

export type Artist = {
    id: number,
    name: string,
    stageName: string,
}
export type Collector = {
    id: number,
    username: string,
    email: string,
}


export type Image = {
    kind: string,
    src: string,
}

export type CollectionInfo = {
    id: number,
    name: string,
    isPublic: boolean,
    ownerId: number,
}


export type Collection = CollectionInfo &{
    owner: Collector,
    collectors?: Collector[],
    disks: DiscInfo[],
}


export type CollectionsOfCollector = {
    collections: CollectionInfo[],
    visibleCollections: CollectionInfo[]
}