<script lang="ts">
    import type { PageData } from './$types'
	import Title from '$cmp/layout/Title.svelte';
	import CollectionPreview from '$cmp/CollectionPreview.svelte';
    export let data: PageData
</script>

<div class="page">
    <Title>
        Your Collections
    </Title>
    <div class="row">
        {#each data.props.owned as collection}
            <CollectionPreview collection={collection} />            
        {/each}
    </div>
    <Title>
        Public & Shared Collections
    </Title>
    <div class="row collections">
        {#each data.props.visible as collection}
        <CollectionPreview collection={collection} />            
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
    .collections{
        flex-wrap: wrap;
        gap: 1rem;
    }
</style>