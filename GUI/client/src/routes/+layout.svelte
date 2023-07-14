<script lang="ts">
	import '../global.css'
	import ErrorLogger from '$cmp/providers/LoggerProvider.svelte'
	import PageTransition from '$cmp/providers/PageTransition.svelte'
	import { page } from '$app/stores'
	import ThemeProvider from '$cmp/providers/ThemeProvider.svelte'
	import PromptProvider from '$cmp/providers/PromptProvider.svelte'
	import Titlebar from '$cmp/layout/Titlebar.svelte';
	import SideMenu from '$cmp/layout/SideMenu.svelte';
	import FaHome from 'svelte-icons/fa/FaHome.svelte'
	import SideMenuOption from '$cmp/layout/SideMenuOption.svelte';
	import { onMount } from 'svelte';

	let maximized = false;
	onMount(() => {
		const idMaximization = window.controls.addOnMaximizationChange((isMaximized) => {
			maximized = isMaximized;
		})
		return () => {
			window.controls.removeOnMaximizationChange(idMaximization)
		}
	})

</script>

<div 
	class="root"
	class:maximized
>
	<ThemeProvider>
		<ErrorLogger>
			<PromptProvider>
				<Titlebar />
				<div class="content">
					<SideMenu>
						<div slot="top" class="links">
							<SideMenuOption to="/">
								<FaHome />
							</SideMenuOption>
						</div>
						<div slot="bottom" class="links">
						</div>
					</SideMenu>
					<PageTransition refresh={$page.url.pathname}>
						<slot />
					</PageTransition>
				</div>
			</PromptProvider>
		</ErrorLogger>
	</ThemeProvider>
</div>

<style lang="scss">
	.content{
		display: flex;
		height: 100%;
		overflow: hidden;
	}
	.links{
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}
	.root{
		background-color: var(--primary);
		color: var(--primary-text);
		border-radius: 0.6rem;
		display: flex;
		flex: 1;
		flex-direction: column;
		overflow: hidden;
	}
	.maximized{
		border-radius: 0;
	}
</style>
