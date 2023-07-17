import type { Collector } from "$common/types/CollectorsTypes";
import { writable } from "svelte/store";


type UserStore ={
    user: Collector | null
}


function createUserStore(){
    const { subscribe, set, update } = writable<UserStore>({
        user: null
    })

    function login(collector: Collector){
        update(s => ({...s, user: collector}))
    }
    return {
        subscribe,
        login
    }
}

export const userStore = createUserStore()