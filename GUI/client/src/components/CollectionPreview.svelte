<script lang="ts">
	import type { CollectionInfo } from '$common/types/CollectorsTypes';

	export let collection: CollectionInfo;
</script>

<a href="\collection\{collection.id}" class="card">
	<div>
		{collection.name}
	</div>

	<div class="tag">
		{#if collection.isPublic}
			🌍
		{:else}
			🔒
		{/if}
	</div>
</a>

<style lang="scss">
	.card {
		padding: 1.4rem;
		border-radius: 0.6rem;
		background-color: var(--secondary);
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
		cursor: pointer;
		position: relative;
	}
    .tag{
        position: absolute;
        top: -0.6rem;
        right: -0.6rem;
        font-size: 1.4rem;
        transform: rotate(-45deg);
    }
	.card:hover {
		transform: rotate(2deg) scale(1.05);
		filter: brightness(1.1);
		box-shadow: 0 0 0.5rem 0.1rem var(--primary);
	}
</style>
