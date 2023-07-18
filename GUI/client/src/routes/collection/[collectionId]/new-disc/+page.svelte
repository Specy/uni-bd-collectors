<script lang="ts">
	import type { PageData } from './$types';
	export let data: PageData;
	import { goto } from '$app/navigation';
	import { toast } from '$stores/toastStore';
	import Input from '$cmp/inputs/Input.svelte';
	import Select from '$cmp/inputs/Select.svelte';
	import Submit from '$cmp/buttons/Submit.svelte';
	import Button from '$cmp/buttons/Button.svelte';
	import FaTrashAlt from 'svelte-icons/fa/FaTrashAlt.svelte';
	import Icon from '$cmp/layout/Icon.svelte';
	import FaPlus from 'svelte-icons/fa/FaPlus.svelte';
	import type {
		Artist,
		Disc,
		DiscInfo,
		Image,
		LabelInfo,
		TrackInfo
	} from '$common/types/CollectorsTypes';
	import Typeahead from 'svelte-typeahead';
	import { toFormattedTime } from '$lib/utils';
	import DiscPreview from '$cmp/DiscPreview.svelte';
	let collection = data.props.collection;
	let options = data.props.populationOptions;

	let title = '';
	let barcode = '';
	let release_year = '';
	let number_of_copies = '1';
	let genre = options.genres[0] || '';
	let disc_format = options.formats[0] || '';
	let disc_status = options.statuses[0] || '';
	let images: Image[] = [];
	let newImageSrc = '';
	let newImageType = options.imageTypes[0] || '';
	let artist: Artist | null = null;
	let label: LabelInfo | null = null;
	let autocompleteArtists: Artist[] = [];
	let autocompleteLabels: LabelInfo[] = [];
	let tracks: TrackInfo[] = [];
	function removeImage(image: Image) {
		images = images.filter((i) => i !== image);
	}
	function addImage() {
		if (!newImageSrc || !newImageType) return;
		images = [...images, { src: newImageSrc, kind: newImageType }];
		newImageSrc = '';
		newImageType = options.imageTypes[0] || '';
	}
	async function fetchArtists(query: string) {
		try {
			const items = await window.api.artistNameAutocomplete(query);
			autocompleteArtists = items || [];
		} catch (e) {
			console.error(e);
			toast.error('There was an error fetching the artists');
		}
	}
	async function fetchLabels(query: string) {
		try {
			const items = await window.api.labelNameAutocomplete(query);
			autocompleteLabels = items || [];
		} catch (e) {
			console.error(e);
			toast.error('There was an error fetching the labels');
		}
	}

	let newArtistName = '';
	let newArtistStagename = '';
	let newLabelName = '';
	async function createNewArtist() {
		try {
			if (!newArtistName || !newArtistStagename) return;
			await window.api.createArtist({ id: -1, name: newArtistName, stageName: newArtistStagename });
			toast.success(`New artist "${newArtistName}" added`);
			newArtistName = '';
			newArtistStagename = '';
		} catch (e) {
			console.error(e);
			toast.error('There was an error creating the artist, it might already be in the database');
		}
	}
	async function createNewLabel() {
		try {
			if (!newLabelName) return;
			await window.api.createLabel({ id: -1, name: newLabelName });
			toast.success(`New label "${newLabelName}" added`);
			newLabelName = '';
		} catch (e) {
			console.error(e);
			toast.error('There was an error creating the label, it might already be in the database');
		}
	}

	let newTrackTitle = '';
	let newTrackDuration = '';
	function createTrack() {
		if (!newTrackTitle || !newTrackDuration) return;
		tracks = [
			...tracks,
			{ title: newTrackTitle, duration: Number(newTrackDuration), id: -1, discId: -1 }
		];
		newTrackTitle = '';
		newTrackDuration = '';
	}
	function removeTrack(track: TrackInfo) {
		tracks = tracks.filter((t) => t !== track);
	}
	async function createDisc() {
		if (!artist || !label) return toast.error('You must select an artist and a label');
		const disc = {
			id: -1,
			title,
			barcode,
			year: Number(release_year),
			quantity: Number(number_of_copies),
			genre,
			format: disc_format,
			conservationStatus: disc_status,
			images,
			artist,
			label,
            artistId: artist.id,
			labelId: label.id,
			tracks,
			collectionId: collection.id
		} as Disc;
		try {
			const id = await window.api.createDisc(disc);
			toast.success('Disc created');
			goto(`/disc/${id}`);
		} catch (e) {
			console.error(e);
			toast.error('There was an error creating the disc');
			return;
		}
	}

	let artistSearch = '';
	let discSearch = '';
	let barcodeSearch = '';
	let searchedDiscs: DiscInfo[] | null = null;
	async function searchDiscs() {
		if (!discSearch && !artistSearch && !barcodeSearch)
			return toast.error('You must fill at least one field');
		try {
			searchedDiscs = null;
			const discs = await window.api.searchDiscBestMatches(
				discSearch,
				barcodeSearch || null,
				artistSearch
			);
			if (!discs) return toast.error('No discs found');
			searchedDiscs = discs;
		} catch (e) {
			console.error(e);
			toast.error('There was an error searching the discs');
		}
	}
	async function loadDisc(disc: DiscInfo) {
		try {
			const detailedDisc = await window.api.getDisc(disc.id);
			if (!detailedDisc) return toast.error('There was an error loading the disc');
			autocompleteArtists = [...autocompleteArtists, detailedDisc.artist];
			autocompleteLabels = [...autocompleteLabels, detailedDisc.label];
			title = detailedDisc.title;
			barcode = detailedDisc.barcode?.toString() || '';
			release_year = detailedDisc.year.toString();
			number_of_copies = detailedDisc.quantity.toString();
			genre = detailedDisc.genre;
			disc_format = detailedDisc.format;
			disc_status = detailedDisc.conservationStatus;
			images = detailedDisc.images;
			tracks = detailedDisc.tracks;
			artist = detailedDisc.artist;
			label = detailedDisc.label;
			toast.success('Disc loaded');
			searchedDiscs = null;
		} catch (e) {
			console.error(e);
			toast.error('There was an error loading the disc');
		}
	}
</script>

{#if options && collection}
	<div class="page">
		<h1>
			Add a new disc to "{collection.name}"
		</h1>
		<div class="column search-disc">
			<form on:submit={searchDiscs} class="column" style="gap: 0.4rem">
				<h2>Search an existing disc</h2>
				<div class="row" style="gap: 0.4rem">
					<Input
						bind:value={discSearch}
						style="background-color: var(--tertiary);"
						outerStyle="flex: 1"
						placeholder="Disc title"
					/>
					<Input
						bind:value={artistSearch}
						style="background-color: var(--tertiary);"
						outerStyle="flex: 1"
						placeholder="Artist name"
					/>
					<Input
						bind:value={barcodeSearch}
						style="background-color: var(--tertiary);"
						outerStyle="flex: 1"
						placeholder="Barcode (optional)"
					/>
				</div>
				<Submit
					value="Search"
					style="width: 100%;"
					disabled={!discSearch && !artistSearch && !barcodeSearch}
				/>
			</form>
			{#if searchedDiscs}
				<div class="column" style="gap: 0.2rem; margin-top: 1rem;">
					<div class="results-header">
						<h3>
							{#if searchedDiscs.length === 0}
								No discs found
							{:else}
								{searchedDiscs.length} discs found
							{/if}
						</h3>
					</div>
					<div class="column" style="gap: 0.2rem">
						{#each searchedDiscs as disc}
							<DiscPreview {disc} disabled style="background-color: var(--tertiary-darker); margin: 0.2rem" hideTag>
								<Button on:click={() => loadDisc(disc)} style="margin: 0.4rem">Load</Button>
							</DiscPreview>
						{/each}
					</div>
				</div>
			{/if}
		</div>
		<form class="card" on:submit={createDisc}>
			<h2 style="margin: 0.4rem 0">Set the info</h2>

			<div class="row input-row">
				<div style="width: 12rem;">Genre</div>

				<Select bind:value={genre} style="width: 100%">
					{#each options.genres as option}
						<option value={option}>{option}</option>
					{/each}
				</Select>
			</div>
			<div class="row input-row">
				<div style="width: 12rem;">Format</div>

				<Select bind:value={disc_format} style="width: 100%">
					{#each options.formats as option}
						<option value={option}>{option}</option>
					{/each}
				</Select>
			</div>
			<div class="row input-row">
				<div style="width: 12rem;">Status</div>

				<Select bind:value={disc_status} style="width: 100%">
					{#each options.statuses as option}
						<option value={option}>{option}</option>
					{/each}
				</Select>
			</div>
			<div class="row input-row">
				<div style="width: 12rem;">Title</div>

				<Input
					bind:value={title}
					outerStyle="width: 100%;"
					style="background-color: var(--tertiary)"
					placeholder="Disc Title"
				/>
			</div>
			<div class="row input-row">
				<div style="width: 12rem;">Barcode</div>

				<Input
					bind:value={barcode}
					outerStyle="width: 100%;"
					style="background-color: var(--tertiary)"
					placeholder="Barcode (optional"
				/>
			</div>
			<div class="row input-row">
				<div style="width: 12rem;">Release year</div>
				<Input
					type="number"
					bind:value={release_year}
					outerStyle="width: 100%;"
					style="background-color: var(--tertiary)"
					placeholder="Release year"
				/>
			</div>
			<div class="row input-row">
				<div style="width: 12rem;">Number of copies</div>

				<Input
					type="number"
					bind:value={number_of_copies}
					outerStyle="width: 100%;"
					style="background-color: var(--tertiary)"
					placeholder="Number of copies"
				/>
			</div>
			<div class="column" style="gap: 0.4rem">
				<h2 style="margin: 0.4rem 0">Add Images</h2>
				<div class="row" style="flex-wrap: wrap; gap: 0.4rem">
					{#each images as image}
						<div class="disc-image">
							<img src={image.src} alt="image" class="preview-image" />
							{image.kind}
							<Button on:click={() => removeImage(image)} style="height: 100%">
								<Icon>
									<FaTrashAlt />
								</Icon>
							</Button>
						</div>
					{/each}
				</div>

				<div class="row" style="gap: 0.4rem">
					<Input
						bind:value={newImageSrc}
						style="background-color: var(--tertiary)"
						placeholder="Image URL"
					/>
					<Select bind:value={newImageType} style="width: 100%">
						{#each options.imageTypes as option}
							<option value={option}>{option}</option>
						{/each}
					</Select>
					<Button on:click={addImage} disabled={!newImageSrc}>
						<Icon>
							<FaPlus />
						</Icon>
					</Button>
				</div>
			</div>
			<div class="column" style="gap: 0.4rem">
				<h2 style="margin: 0.4rem 0">Choose the artist</h2>
				<Typeahead
					hideLabel
					data={autocompleteArtists}
					value={artist?.stageName}
					style="border-radius: 0.4rem; border: none !important; border-radius: 0.4rem; background-color: var(--tertiary); color: var(--tertiary-text)"
					extract={(item) => item.stageName}
					on:select={(e) => {
						const value = e.detail;
						if (!value) return;
						artist = value.original;
					}}
					on:input={(e) => {
						const value = e.target.value;
						if (value.length <= 1) return;
						fetchArtists(value);
					}}
				>
					<svelte:fragment slot="no-results">
						<div>No artists found, create one</div>
					</svelte:fragment>
				</Typeahead>
				<div class="row" style="gap: 0.4rem">
					<Input
						bind:value={newArtistName}
						style="background-color: var(--tertiary)"
						placeholder="Artist name"
					/>
					<Input
						bind:value={newArtistStagename}
						style="background-color: var(--tertiary)"
						placeholder="Artist stage name (unique)"
					/>
					<Button
						style="margin-left: auto"
						on:click={createNewArtist}
						disabled={!newArtistName || !newArtistStagename}
					>
						Create a new artist
					</Button>
				</div>
			</div>
			<div class="column" style="gap: 0.4rem">
				<h2 style="margin: 0.4rem 0">Choose the label</h2>
				<Typeahead
					hideLabel
					data={autocompleteLabels}
					value={label?.name}
					style="border-radius: 0.4rem; border: none !important; border-radius: 0.4rem; background-color: var(--tertiary); color: var(--tertiary-text)"
					extract={(item) => item.name}
					on:select={(e) => {
						const value = e.detail;
						if (!value) return;
						label = value.original;
					}}
					on:input={(e) => {
						const value = e.target.value;
						if (value.length <= 1) return;
						fetchLabels(value);
					}}
				>
					<svelte:fragment slot="no-results">
						<div>No labels found, create one</div>
					</svelte:fragment>
				</Typeahead>
				<div class="row" style="gap: 0.4rem">
					<Input
						bind:value={newLabelName}
						style="background-color: var(--tertiary)"
						placeholder="Label name"
					/>
					<Button style="margin-left: auto" on:click={createNewLabel} disabled={!newLabelName}>
						Create a new label
					</Button>
				</div>
			</div>

			<div class="column" style="gap: 0.4rem">
				<h2 style="margin: 0.4rem 0">Add tracks</h2>
				{#each tracks as track}
					<div class="track">
						<div>{track.title}</div>
						<div class="row" style="align-items: center; gap: 1rem">
							<div>{toFormattedTime(track.duration)}</div>
							<Button on:click={() => removeTrack(track)}>
								<Icon>
									<FaTrashAlt />
								</Icon>
							</Button>
						</div>
					</div>
				{/each}
				<div class="row" style="gap: 0.4rem">
					<Input
						bind:value={newTrackTitle}
						style="background-color: var(--tertiary)"
						placeholder="Track title"
					/>
					<Input
						bind:value={newTrackDuration}
						style="background-color: var(--tertiary)"
						placeholder="Track duration (seconds)"
						type="number"
					/>
					<Button
						on:click={createTrack}
						disabled={!newTrackTitle || !newTrackDuration}
						style="margin-left: auto"
					>
						<Icon>
							<FaPlus />
						</Icon>
					</Button>
				</div>
			</div>

			<Submit
				value="Add Disc"
				style="width: 100%;"
				disabled={!title ||
					!release_year ||
					!number_of_copies ||
					!genre ||
					!disc_format ||
					!disc_status || 
					!artist ||
					!label}
			/>
		</form>
	</div>
{/if}

<style lang="scss">
	.page {
		padding: 1rem;
		display: flex;
		flex-direction: column;
		overflow-y: auto;
	}
	.results-header {
		padding: 0.4rem 1rem;
		border-radius: 0.2rem;
		border-top-left-radius: 0.4rem;
		border-top-right-radius: 0.4rem;
		background-color: var(--tertiary);
	}
	.track {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 0.4rem;
		padding: 0.4rem;
		padding-left: 1.2rem;
		border-radius: 0.4rem;
		background-color: var(--tertiary);
	}
	.card,
	.search-disc {
		display: flex;
		flex-direction: column;
		padding: 1rem;
		border-radius: 0.6rem;
		background-color: var(--secondary);
		width: 41rem;
		margin: 2rem auto;
		gap: 0.5rem;
	}

	.input-row {
		display: flex;
		align-items: center;
		gap: 1rem;
	}
	.disc-image {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		background-color: var(--tertiary);
		padding: 0.4rem;
		border-radius: 0.6rem;
		width: min-content;
		.preview-image {
			height: 3rem;
			width: 3rem;
			border-radius: 0.4rem;
		}
	}
	.no-results {
		padding: 0.4rem;
		border-top-left-radius: 0.4rem;
		border-top-right-radius: 0.4rem;
		background-color: var(--tertiary);
	}
	:global([data-svelte-typeahead]) {
		width: 100%;
		background-color: var(--tertiary) !important;
		border-radius: 0.4rem;
		color: var(--tertiary-color) !important;
		:global(li) {
			background-color: var(--tertiary) !important;
			color: var(--tertiary-text) !important;
			border-bottom: unset !important;
		}
		:global(li:first-child) {
			border-top-left-radius: 0.4rem;
			border-top-right-radius: 0.4rem;
		}
		:global(li:last-child) {
			border-bottom-left-radius: 0.4rem;
			border-bottom-right-radius: 0.4rem;
		}
		:global(ul) {
			margin-top: 0.2rem !important;
			gap: 0.1rem !important;
			border-radius: 0.4rem;
		}
	}
</style>
