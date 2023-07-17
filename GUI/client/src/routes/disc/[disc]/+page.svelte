<script lang="ts">
	import Button from '$cmp/buttons/Button.svelte';
import type { Disc } from '$common/types/CollectorsTypes.js';
	import { toFormattedTime } from '$lib/utils.js';
	import type { PageData } from './$types.js';
	export let data: PageData;
	$: disc = data.props.disc as Disc;

	function findPreviewImage(disc: Disc) {
		const frontImage = disc.images.find((image) => image.kind === 'Front');
		if (frontImage) return frontImage.src;
		return disc.images[0]?.src;
	}
	$: mainImage = findPreviewImage(disc);
</script>

<div class="column page">
	<div class="row" style="gap: 1rem">
		<img src={mainImage} alt="Disc preview image" class="main-image" />
		<div class="column" style="gap: 0.8rem">
			<h1>
				{disc.title}
			</h1>
			<div>
				{disc.artist} - {disc.label}
			</div>
			<div>
				{disc.year} - {disc.genre}
			</div>
			<div>
				{disc.format} - {disc.quantity}x
			</div>
			<div>
				Barcode: {disc.barcode || 'Unknown'}
			</div>
			<div class="row" style="gap: 1rem; flex: 1">
				{#each disc.images as image}
					<img src={image.src} alt="Disc image" class="sub-image" />
				{/each}
			</div>
		</div>
	</div>
	<h2>Tracks</h2>
	<div class="column" style="gap: 0.4rem">
		{#each disc.tracks as track}
			<a class="row track" style="gap: 1rem" href="/disc/{track.discId}/track/{track.id}">
				<div>
					{track.title}
				</div>

				<div>
					{toFormattedTime(track.duration)}
				</div>
			</a>
		{/each}
	</div>
    <a href="/collection/{disc.collectionId}"> 
        <Button>
            Back to collection
        </Button>
    </a>
</div>

<style lang="scss">
	.page {
		padding: 1rem;
		gap: 1rem;
	}
    .track{
        padding: 0.5rem 1rem;
        background-color: var(--secondary);
        border-radius: 0.2rem;
        display: flex;
        justify-content: space-between;
        transition: all 0.2s;
    }
    .track:hover{
        filter: brightness(1.1);
        transform: scale(0.995);
    }
	.sub-image {
		max-width: 8rem;
		aspect-ratio: 1;
		object-fit: cover;
		border-radius: 0.3rem;
		box-shadow: 0 0 0.5rem rgba(0, 0, 0, 0.2);
	}
	.main-image {
		max-width: 20rem;
		aspect-ratio: 1;
		object-fit: cover;
		border-radius: 0.3rem;
		box-shadow: 0 0 1rem rgba(0, 0, 0, 0.2);
	}
</style>
