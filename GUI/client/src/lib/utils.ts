
export function clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
}

export type Timer = NodeJS.Timeout | number;

export function createDebouncer(delay:number){
    let timeoutId:Timer
    return function(callback:() => void){
        clearTimeout(timeoutId)
        timeoutId = setTimeout(callback, delay)
    }
}
export default function blobDownloader(blob:Blob,fileName:string){
    const a = document.createElement('a')
    a.style.display = 'none'
    document.body.appendChild(a)
    a.href = URL.createObjectURL(blob)
    a.download = fileName
    a.click()
    a.remove()
    URL.revokeObjectURL(a.href)
}
export function getErrorMessage(error: any): string{
    if(typeof error !== "object"){
        return error
    }
    if(error.message) return error.message
    return JSON.stringify(error)
}

export function capitalize(str:string){
    return str[0].toUpperCase() + str.slice(1)
}

export function toResourceUrl(path:string){
    return `resource://${path.replace(/\\/g, "/")}`
}

export function delay(ms:number){
    return new Promise(resolve => setTimeout(resolve, ms))
}


export function toFormattedTime(seconds: number) {
    return new Date(seconds * 1000).toLocaleTimeString([], {
        minute: 'numeric',
        second: '2-digit'
    }).replace(/^0+/, '');
}