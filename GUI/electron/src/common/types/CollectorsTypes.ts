type Disk = {
    id: number,
    artists: Artist[],
    tracks: Track[],
    images: Image[],
    title: string,
    barcode?: string,
    year: number,
    genre: string,
    format: Format, 
    label: RecordCompany,
    quantity: number,
    conservationStatus: ConservationStatus,
}
type RecordCompany = {
    id: number,
    name: string,
}

enum Format {
    CD = "CD",
    DVD = "DVD",
    VINYL = "VINYL",
    CASSETTE = "CASSETTE",
}

enum ConservationStatus {
    NEW = "NEW",
    GOOD = "GOOD",
    BAD = "BAD",
    VERY_BAD = "VERY_BAD",
}


type Track = {
    id: number,
    title: string,  
    duration: number,
    artists: ArtistRole[]
}

type ArtistRole = {
    artist: Artist,
    role: string,
}

type Artist = {
    id: number,
    name: string,
}
type Collector = {
    id: number,
    nickname: string,
    email: string,
}

enum ImageKind{
    COVER = "COVER",
    BACK = "BACK",
    DISC = "DISC",
    OTHER = "OTHER",
}

type Image = {
    kind: ImageKind,
    src: string,
}

type Collection = {
    id: number,
    name: string,
    isPublic: boolean
    collectors?: Collector[],
    disks: Disk[],
}