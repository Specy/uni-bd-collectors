<script lang="ts">
	import Button from '$cmp/buttons/Button.svelte';
	import type { Track } from '$common/types/CollectorsTypes.js';
	import { toFormattedTime } from '$lib/utils.js';
	import type { PageData } from './$types.js';
	export let data: PageData;
	$: track = data.props.track as Track;
</script>

<div class="column page">
	<h1>
		{track.title} - {toFormattedTime(track.duration)}m
	</h1>
	<div class="row" style="gap: 0.4rem; flex-wrap: wrap">
		{#each track.artists as artistContribution}
			<div class="row artist-contribution" style="gap: 1rem">
				<div class="artist-name">
					{artistContribution.artist.name}
				</div>
				<div>
					{artistContribution.role}
				</div>
			</div>
		{/each}
	</div>
	<a href="/disc/{track.discId}">
		<Button>Back to disc</Button>
	</a>
</div>

<style lang="scss">
	.page {
		padding: 1rem;
		gap: 2rem;
	}
	.artist-contribution {
		background-color: var(--secondary);
		border-radius: 0.2rem;
		overflow: hidden;
		display: flex;
		align-items: center;
		padding-right: 0.8rem;
		transition: all 0.2s;
	}
	.artist-name {
		background-color: var(--accent);
		color: var(--accent-text);
		padding: 0.2rem 0.4rem;
	}
</style>
