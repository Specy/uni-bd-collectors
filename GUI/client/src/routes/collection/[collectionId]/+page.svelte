<script lang="ts">
	import type { PageData } from './$types';
	import Title from '$cmp/layout/Title.svelte';
	import { capitalize } from '$lib/utils';
	import DiscPreview from '$cmp/DiscPreview.svelte';
	import { userStore } from '$stores/userStore';
	import Button from '$cmp/buttons/Button.svelte';
	import { toast } from '$stores/toastStore';
	import FaLock from 'svelte-icons/fa/FaLock.svelte';
	import FaUnlock from 'svelte-icons/fa/FaUnlock.svelte';
	import Icon from '$cmp/layout/Icon.svelte';
	export let data: PageData;
    import FaUserAltSlash from 'svelte-icons/fa/FaUserAltSlash.svelte'
	import Input from '$cmp/inputs/Input.svelte';
	import Submit from '$cmp/buttons/Submit.svelte';
	import { Prompt } from '$stores/promptStore';
	import type { Collector } from '$common/types/CollectorsTypes';
	$: collection = data.props.collection;
	$: isOwned = $userStore.user?.id === collection.owner.id;
    let userMailToAdd = ''

	async function toggleVisibility() {
		const prev = collection.isPublic;
		collection.isPublic = !collection.isPublic;
		try {
			await window.api.setCollectionVisibility(collection.id, !prev);
		} catch (e) {
			collection.isPublic = prev;
			toast.error('Error changing collection visibility');
		}
	}
    async function removeCollector(collector: Collector){
        try{
            const confirm = await Prompt.confirm(`Are you sure you want to remove "${collector.username}" from this collection?`)
            if(!confirm) return
            await window.api.setCollectorInCollection(collection.id, collector.id, false)
            collection.collectors = collection.collectors.filter((c: any) => c.id !== collector.id)
        }catch(e){
            toast.error('Error removing collector')
        }
    }
    async function addNewCollector(){
        try{
            const collector = await window.api.getCollectorByMail(userMailToAdd)
            if(!collector){
                toast.error('Collector not found')
                return
            }
            const exists = collection.collectors.find((c: any) => c.id === collector.id)
            if(exists){
                toast.error('Collector is already part of this collection')
                return
            }
            if(collector.id === collection.owner.id){
                toast.error('Collector is already the owner of this collection')
                return
            }
            const confirm = await Prompt.confirm(`Are you sure you want to add "${collector.username}" to this collection?`)
            if(!confirm) return
            await window.api.setCollectorInCollection(collection.id, collector.id, true)
            collection.collectors = [...collection.collectors, collector]
            userMailToAdd = ''
        }catch(e){
            console.error(e)
            toast.error(`Error adding new collector`)
        }
    }
</script>

<div class="page">
	<Title noMargin>
		{capitalize(collection.owner.username)}'s collection "{collection.name}"
	</Title>
	{#if collection.collectors.length > 0}
		<div class="row" style="align-items: center; gap: 0.5rem">
			<span>Shared with: </span>
			{#each collection.collectors as collector}
				<div class="collector">
					<span>{collector.username}</span>
				</div>
			{/each}
		</div>
	{/if}
	<div class="column discs">
		<div class="discs-header">Discs</div>
		{#each collection.disks as disc}
			<DiscPreview {disc} />
		{/each}
	</div>
	{#if isOwned}
		<Button on:click={toggleVisibility} cssVar={collection.isPublic ? 'accent' : 'tertiary'} style="padding-left: 0.6rem">
			{#if collection.isPublic}
				<Icon style="margin-right: 0.4rem">
					<FaLock />
				</Icon>
				<span>Make Private</span>
			{:else}
				<Icon style="margin-right: 0.4rem">
					<FaUnlock />
				</Icon>
				<span>Make Public</span>
			{/if}
		</Button>
        
        <h2 style="margin-top: 2rem;">
            Member Collectors
        </h2>
        <div class="column" style="gap:0.3rem">
            {#each collection.collectors as collector}
            <div class="row existing-collector" style="align-items: center; justify-content: space-between;">
                {collector.username} 
                <Button on:click={() => removeCollector(collector)}>
                    <Icon>
                        <FaUserAltSlash />
                    </Icon>
                </Button>
            </div>
        {/each}
        </div>

        <h3>
            Add collector
        </h3>
        <form class="row" style="gap: 0.4rem" on:submit|preventDefault={addNewCollector} >
            <Input bind:value={userMailToAdd} placeholder="email"/>
            <Submit value="Add" disabled={userMailToAdd === ""}/>
        </form>
	{/if}
</div>

<style lang="scss">
	.page {
		padding: 2rem;
		display: flex;
		flex-direction: column;
		gap: 1rem;
		flex: 1;
	}
    .existing-collector{
        padding: 0.3rem;
        border-radius: 0.6rem;
        padding-left: 1rem;
        background-color: var(--secondary);
    }
	.discs-header {
		font-size: 1.2rem;
		font-weight: 600;
		padding: 1rem;
		border-radius: 0.2rem;
		border-top-left-radius: 0.4rem;
		border-top-right-radius: 0.4rem;
		background-color: var(--secondary-darker);
	}
	.discs {
		gap: 0.2rem;
		border-radius: 0.4rem;
	}
	:global(.discs > div:last-child) {
		border-bottom-left-radius: 0.4rem;
		border-bottom-right-radius: 0.4rem;
	}
	.collector {
		padding: 0.3rem 1rem;
		border-radius: 0.3rem;
		background-color: var(--secondary);
	}
</style>
