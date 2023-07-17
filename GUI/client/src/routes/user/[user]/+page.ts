import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const ssr = false

export const load = (async ({ params }) => {
    const data = await window.api.getCollectionsOfCollector(Number(params.user), true)
    console.log(data)
    if(!data) throw error(404, 'Collector not found')

    return {
        props: {
            owned: data.collections,
            visible: data.visibleCollections
        }
    }
}) satisfies PageServerLoad;