<script lang="ts">
	import type { DiscInfo } from "$common/types/CollectorsTypes";
    export let disc: DiscInfo
</script>

<a class="disc row" href="disc/{disc.id}">
    <div class="title">
        {disc.title}
    </div>
    <div>
        {disc.artist} - {disc.label}
    </div>
    <div>
        {disc.year} - {disc.genre}
    </div>
    <div style="max-width: 6rem; text-align: end">
        {disc.format}
    </div>
    <div class="tag">
        {disc.quantity || 100}
    </div>
</a>


<style lang="scss">
    .disc{
        padding: 0.5rem 1rem;
        background-color: var(--secondary);
        position: relative;
        border-radius: 0.2rem;
        transition: all 0.2s;
        gap: 1rem;
    }
    .disc > div{
        flex: 1;
    }
    .title{
        width: 30%;
        font-size: 1rem;
        text-overflow: ellipsis;
        overflow: hidden;
        white-space: nowrap;

    }
    .disc:hover{
        filter: brightness(1.1);
        transform: scale(0.995);
    }
    .tag{
        top: 0rem;
        right: 0rem;
        border-radius: 0.3rem;
        text-align: center;
        padding: 0.2rem;
        max-width: 2.4rem;
        background-color: var(--tertiary);
        position: absolute;
        transform-origin: top right;
        transform: rotate(45deg) translate(50%, -50%);
    }

</style>