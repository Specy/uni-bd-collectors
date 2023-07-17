import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
export const ssr = false

export const load = (async ({ params }) => {
    const data = await window.api.getDisc(Number(params.disc))
    if(!data) throw error(404, 'Collector not found')

    return {
        props: {
            disc: data
        }
    }
}) satisfies PageServerLoad;