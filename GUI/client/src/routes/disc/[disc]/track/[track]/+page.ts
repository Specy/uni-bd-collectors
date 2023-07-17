import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const ssr = false

export const load = (async ({ params }) => {
    const data = await window.api.getTrack(Number(params.track))
    if(!data) throw error(404, 'Collector not found')

    return {
        props: {
            track: data
        }
    }
}) satisfies PageServerLoad;