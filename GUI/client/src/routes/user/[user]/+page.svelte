<script lang="ts">
	import type { PageData } from './$types';
	import Title from '$cmp/layout/Title.svelte';
	import CollectionPreview from '$cmp/CollectionPreview.svelte';
	import { Prompt } from '$stores/promptStore';
	import { userStore } from '$stores/userStore';
	import { goto } from '$app/navigation';
	export let data: PageData;
    async function createNewCollection(){
        const name = await Prompt.askText('Enter collection name', true);
        if(!name) return;
        const collection = await window.api.createCollection(name as string, true, $userStore.user!.id);
        if(collection){
            goto(`/collection/${collection.id}`);
        }
    }
</script>

<div class="page">
	<Title>Your Collections</Title>
	<div class="row collections">
		{#each data.props.owned as collection}
			<CollectionPreview {collection} />
		{/each}
		<div class="new-card" on:click={createNewCollection}>Create new collection</div>
	</div>
	<Title>Public & Shared Collections</Title>
	<div class="row collections">
		{#each data.props.visible as collection}
			<CollectionPreview {collection} />
		{/each}
	</div>
</div>

<style lang="scss">
	.page {
		padding: 2rem;
		display: flex;
		flex-direction: column;
		gap: 1rem;
		flex: 1;
	}
	.new-card {
		padding: 1.4rem;
		border-radius: 0.6rem;
		background-color: var(--tertiary);
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
		cursor: pointer;
		position: relative;
	}
    .new-card:hover {
        filter: brightness(1.1);
        box-shadow: 0 0 0.5rem 0.1rem var(--primary);
    }
	.collections {
		flex-wrap: wrap;
		gap: 1rem;
	}
</style>
