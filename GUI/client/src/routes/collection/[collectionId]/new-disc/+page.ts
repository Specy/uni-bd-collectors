import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const ssr = false

export const load = (async ({ params }) => {
    const data = await window.api.getCollection(Number(params.collectionId))
    const populationOptions = await window.api.getPopulationOptions()
    if(!data) throw error(404, 'Collector not found')
    return {
        props: {
            collection: data,
            populationOptions
        }
    }
}) satisfies PageServerLoad;